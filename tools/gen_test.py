# Faithful Python port of Sudoku/Generator.swift for local verification.
import random, time, sys
R={'Easy':(36,40),'Medium':(45,50),'Hard':(52,56)}
def ok(b,i,n):
    r,c=divmod(i,9); br,bc=r//3*3,c//3*3
    for k in range(9):
        if b[r*9+k]==n or b[k*9+c]==n or b[(br+k//3)*9+bc+k%3]==n: return False
    return True
def fill(b):
    if 0 not in b: return True
    i=b.index(0); ns=list(range(1,10)); random.shuffle(ns)
    for n in ns:
        if ok(b,i,n):
            b[i]=n
            if fill(b): return True
    b[i]=0; return False
def count(b,cap=2):
    best=-1;bc=[]
    for i in range(81):
        if b[i]==0:
            c=[n for n in range(1,10) if ok(b,i,n)]
            if not c: return 0
            if best<0 or len(c)<len(bc):
                best,bc=i,c
                if len(c)==1: break
    if best<0: return 1
    t=0
    for n in bc:
        b[best]=n; t+=count(b,cap-t); b[best]=0
        if t>=cap: break
    return t
def generate(d,budget=2.0):
    lo,hi=R[d]; target=random.randint(lo,hi); st=time.time(); best=None; be=-1
    while True:
        sol=[0]*81; fill(sol); p=sol[:]; e=0
        idx=list(range(81)); random.shuffle(idx)
        for i in idx:
            if e>=target: break
            v=p[i]; p[i]=0
            if count(p[:])==1: e+=1
            else: p[i]=v
        if e>be: best,bs,be=p,sol,e
        if be>=target or time.time()-st>=budget: break
    return best,bs,target
def valid_solution(s):
    return all(ok([0 if j==i else s[j] for j in range(81)],i,s[i]) for i in range(81))
for d in R:
    N=50; fails=0; empt=[]; miss=0; ts=[]
    for _ in range(N):
        t=time.time(); p,s,tg=generate(d); ts.append(time.time()-t)
        e=p.count(0); empt.append(e)
        if count(p[:])!=1 or not valid_solution(s) or any(p[i] and p[i]!=s[i] for i in range(81)): fails+=1
        if not (R[d][0]<=e<=R[d][1]): miss+=1
    print(f"{d}: {N} puzzles, failures={fails}, empty min/max={min(empt)}/{max(empt)}, out-of-range={miss}, avg {sum(ts)/N:.2f}s max {max(ts):.2f}s",flush=True)
