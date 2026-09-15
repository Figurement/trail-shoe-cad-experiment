import sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import numpy as np
ref_path, cad_path, out, = sys.argv[1:4]
# reference registration (px per mm, origin px for x=0 / z=0), cad registration
rs, rx0, ry0 = float(sys.argv[4]), float(sys.argv[5]), float(sys.argv[6])
cs, cx0, cy0 = float(sys.argv[7]), float(sys.argv[8]), float(sys.argv[9])
flip = len(sys.argv) > 10 and sys.argv[10] == 'flip'
ref = Image.open(ref_path).convert('RGB'); ref = ref.resize((2000, int(ref.height*2000/ref.width)), Image.LANCZOS)
cad = Image.open(cad_path).convert('RGB')
if flip:
    cad = cad.transpose(Image.FLIP_LEFT_RIGHT); cx0 = cad.width - cx0
k = rs/cs
cad2 = cad.resize((int(cad.width*k), int(cad.height*k)), Image.LANCZOS)
ox, oy = int(rx0 - cx0*k), int(ry0 - cy0*k)
canvas = Image.new('RGB', ref.size, (248,248,248)); canvas.paste(cad2, (ox, oy))
a = np.array(canvas).astype(int); bg = np.array([248,248,248])
mask = (np.abs(a-bg).sum(2) > 40)
# edges of the cad colour regions
# classify by chromaticity (shading-invariant) into placeholder colour classes
f = a.astype(float); ssum = f.sum(2, keepdims=True)+1e-6; chro = f/ssum
classes = {'mesh':(0.10,0.42,0.52),'mid':(0.20,0.55,0.95),'org':(1.0,0.42,0.28),'blk':(0.33,0.33,0.34),
           'neon':(0.75,1.0,0.10),'lace':(0.15,0.60,0.60),'logo':(0.33,0.335,0.34),'gry':(0.30,0.34,0.38),'collar':(0.12,0.35,0.45)}
cc = np.array([np.array(v)/sum(v) for v in classes.values()])
d = ((chro[:,:,None,:]-cc[None,None,:,:])**2).sum(3)
lab = d.argmin(2)
lum = f.sum(2)
# separate black / white / grey by luminance among the neutral classes
neutral = (np.abs(chro-1/3).sum(2) < 0.06)
lab[neutral & (lum < 200)] = 100; lab[neutral & (lum >= 200) & (lum < 560)] = 101; lab[neutral & (lum >= 560)] = 102
lab[~mask] = -1
e = np.zeros_like(mask)
e[1:,:] |= lab[1:,:] != lab[:-1,:]; e[:,1:] |= lab[:,1:] != lab[:,:-1]
e &= mask
edge = Image.fromarray((e*255).astype('uint8')).filter(ImageFilter.MaxFilter(3))
blend = Image.blend(ref, canvas, 0.45)
ov = ref.copy(); ov.paste(Image.new('RGB', ref.size, (255,0,255)), mask=edge)
def grid(img):
    d = ImageDraw.Draw(img)
    for x in range(0, 320, 10):
        X = rx0 + x*rs; d.line([(X,0),(X,img.height)], fill=(255,255,0) if x%50==0 else (200,200,120), width=1)
        if x%50==0: d.text((X+2, 4), str(x), fill=(255,255,0))
    for z in range(0, 160, 10):
        Y = ry0 - z*rs; d.line([(0,Y),(img.width,Y)], fill=(255,255,0) if z%50==0 else (200,200,120), width=1)
        if z%50==0: d.text((4, Y+2), str(z), fill=(255,255,0))
    return img
grid(blend).save(out+'_blend.png'); grid(ov).save(out+'_edges.png')
print('saved', out)
