from PIL import Image, ImageDraw
S=4096; im=Image.new("RGB",(S,S),"black"); d=ImageDraw.Draw(im)
W=(255,255,255); G=(212,175,55)
m=640; L=S-2*m; c=L/3
# outer angular frame: square with chamfered corners
ch=340; t=210
def chamfer(o,cl):
    a,b=m-o,S-m+o
    pts=[(a+ch,a),(b-ch,a),(b,a+ch),(b,b-ch),(b-ch,b),(a+ch,b),(a,b-ch),(a,a+ch)]
    d.polygon(pts,fill=cl)
chamfer(0,W); 
a,b=m+t,S-m-t; ch2=ch-60
d.polygon([(a+ch2,a),(b-ch2,a),(b,a+ch2),(b,b-ch2),(b-ch2,b),(a+ch2,b),(a,b-ch2),(a,a+ch2)],fill="black")
# inner grid lines in gold
g=150
for i in (1,2):
    x=m+c*i; d.rectangle([x-g/2,m+t+120,x+g/2,S-m-t-120],fill=G); d.rectangle([m+t+120,x-g/2,S-m-t-120,x+g/2],fill=G)
# center cell: gold angular slash (SpaceX-like swoosh)
cx=S/2; r=c/2-260
d.polygon([(cx,cx-r),(cx+r,cx),(cx,cx+r),(cx-r,cx)],fill=W)
im.resize((1024,1024),Image.LANCZOS).save("/workspace/sudoku-icon.png")