"""Portable regression tests; ExifTool path is supplied as the first argument."""
import hashlib, os, re, struct, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, TiffImagePlugin, PngImagePlugin
ROOT=Path(__file__).resolve().parents[1]
SCRIPT=(ROOT/'Resources/Remove_EXIF.command').read_text()
PERL=SCRIPT.split("<<'PERL'\n",1)[1].split('\nPERL',1)[0]
EXTENDED=SCRIPT.split('clean_extended() {',1)[1].split('\nok=0',1)[0]
EXTENDED='clean_extended() {'+EXTENDED
TOOL=str(Path(sys.argv[1]).resolve())
def read_tags(p):
    return subprocess.check_output([TOOL,'-s','-Artist','-XMP:Creator','-GPS:all','-Software',str(p)])
def extended(p,out):
    return subprocess.run(['bash','-c',EXTENDED+'\nEXIFTOOL="$1"; clean_extended "$2" "$3"','test',TOOL,str(p),str(out)],capture_output=True)
with tempfile.TemporaryDirectory() as tmp:
    d=Path(tmp)
    for kind in ['JPEG','PNG']:
        src=d/('native.'+kind.lower()); dst=d/'out'
        im=Image.new('RGB',(12,10),(50,100,150))
        if kind=='JPEG':
            exif=Image.Exif(); exif[315]='Private Creator'; im.save(src,exif=exif)
        else:
            info=PngImagePlugin.PngInfo(); info.add_text('Creator','AI Tool'); im.save(src,pnginfo=info)
        expected=Image.open(src).tobytes()
        subprocess.run(['perl','-',str(src),str(dst)],input=PERL.encode(),check=True)
        assert Image.open(dst).tobytes()==expected
        assert b'Private Creator' not in dst.read_bytes() and b'AI Tool' not in dst.read_bytes()
    src=d/'multipage.tif'; dst=d/'clean.tif'
    info=TiffImagePlugin.ImageFileDirectory_v2();info[315]='Private Creator';info[305]='AI Tool';info[274]=6
    Image.new('RGB',(8,10),'red').save(src,tiffinfo=info,compression='tiff_lzw')
    subprocess.run([TOOL,'-overwrite_original','-XMP:Creator=Private Creator',str(src)],check=True,capture_output=True)
    result=extended(src,dst); assert result.returncode==0,result.stdout+result.stderr
    assert not read_tags(dst)
    assert subprocess.check_output([TOOL,'-n','-s3','-Orientation',str(dst)]).strip()==b'6'
    before=Image.open(src); after=Image.open(dst)
    assert before.n_frames==after.n_frames==1
    for i in range(1):
        before.seek(i);after.seek(i); assert before.tobytes()==after.tobytes()
    multi=d/'multi.tif'
    Image.new('RGB',(8,10),'red').save(multi,save_all=True,append_images=[Image.new('RGB',(8,10),'blue')])
    assert extended(multi,d/'multi-out').returncode!=0
    # Official ExifTool HEIC fixture; confirm compressed media bytes are unchanged.
    src=d/'image.heic';dst=d/'clean.heic'
    src.write_bytes((Path(TOOL).parent/'t/images/QuickTime.heic').read_bytes())
    subprocess.run([TOOL,'-overwrite_original','-XMP:Creator=Private Creator',str(src)],check=True,capture_output=True)
    def media(p):
        data=p.read_bytes();offset=0;blocks=[]
        while offset<len(data):
            size,kind=struct.unpack_from('>I4s',data,offset); header=8
            if size==1: size=struct.unpack_from('>Q',data,offset+8)[0];header=16
            if size==0:size=len(data)-offset
            assert size>=header
            if kind==b'mdat': blocks.append(data[offset+header:offset+size])
            offset+=size
        assert blocks
        return blocks
    result=extended(src,dst);assert result.returncode==0,result.stdout+result.stderr
    assert not read_tags(dst);original=media(Path(TOOL).parent/'t/images/QuickTime.heic'); cleaned=media(dst)
    assert len(original)==len(cleaned)
    for a,b in zip(original,cleaned): assert b.endswith(a)  # ExifTool may prepend an empty EXIF item
    bad=d/'broken.tif';bad.write_bytes(b'not a TIFF')
    result=extended(bad,d/'bad-out'); assert result.returncode!=0
    print('PASS: JPEG/PNG pixels; TIFF pixels and orientation, multipage rejection; HEIC media; metadata removal; invalid input rejection')
