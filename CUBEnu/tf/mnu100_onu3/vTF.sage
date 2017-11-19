#!/usr/bin/python
import numpy as np

doPlot = False

#z of fE

Z=15
if (Z==20):
    iE = 20
    ZA = 20.1
    ZB = 19.9
    ZE = 20.0
if (Z==15):
    iE = 15
    ZA = 15.1
    ZB = 14.9
    ZE = 15.0
if (Z==10):
    iE = 10.0
    ZA = 10.1
    ZB = 9.9
    ZE = 10.0
if (Z==5):
    iE = 5
    ZA = 5.1
    ZB = 4.9
    ZE = 5.0
if (Z==0):
    iE = 0
    ZA = 0.1
    ZB = 0.0
    ZE = 0.05
    print "Using z = 0.05 as proxy for z=0"

#Location of transfer functions
dir = './' 
prefix = 'mnu100_onu3_transfer_out_z'
suffix = '.dat'

fE = prefix+str(Z)+suffix
fA = prefix+str(ZA)+suffix
fB = prefix+str(ZB)+suffix
fO = prefix+str(Z)+'_v'+suffix

#scale factor
a = 1.0/(1.0+ZE)

#Cosmological parameters
OM = 0.327068#1.0-0.672932
OL = 1-OM#1.0 - OM

#Assuming k-col in h/Mpc
H0 = 100

#Compute H(a)
h = 0.67
H = H0 * ( OM*a**-3 + OL )**0.5

#Get transfer functions into arrays
tfE = np.genfromtxt(dir+fE)
tfA = np.genfromtxt(dir+fA)
tfB = np.genfromtxt(dir+fB)

if(tfA.shape!=tfB.shape or tfA.shape!=tfE.shape):
    print "ERROR - TRANSFER FUNCTIONS DIFFERENT SHAPE"
    
Nk = tfA.shape[0]
Nc = tfA.shape[1]

#Check if transfer functions have same k-values
if( not( np.array_equal( tfA[:,0], tfB[:,0] ) and np.array_equal( tfA[:,0], tfE[:,0] ) ) ):
    print "ERROR - TRANSFER FUNCTIONS HAVE DIFFERENT K-VALUES"
    
tfV = np.zeros((Nk,Nc))
for k in range(Nk):
    for c in range(Nc):
        if (c==0):
            tfV[k,c] = tfE[k,c]
        else:
            tfV[k,c] = (H/tfE[k,0])*(tfA[k,c]-tfB[k,c])/(ZA-ZB) #proper km/s
    
np.savetxt(dir+fO,tfV)

#Flatness plot:
if doPlot:
    F = (tfV[:,1]/tfE[:,1])/(-1.0*a*H*(OM*a**-3/(OM*a**-3+OL))**0.6/tfE[:,0])   
    Fplot = list_plot( zip(tfV[:,0],F), plotjoined=true )
    Fplot.show()

    #Test plot
    for k in range(Nk):
        for c in range(Nc):
            if (c==0):
                tfV[k,c] = tfE[k,c]
            else:
                tfV[k,c] = tfV[k,c] * tfE[k,0]**2 * h**2 
            
    D=2.42*10**-9
    spd = 1#299792.458
    plot = list_plot(zip(tfV[:,0],tfV[:,1]**2*D/spd**2),plotjoined=true,color='blue')
    plot+= list_plot(zip(tfV[:,0],tfV[:,2]**2*D/spd**2),plotjoined=true,color='red')
    plot+= list_plot(zip(tfV[:,0],(tfV[:,2]-tfV[:,1])**2*D/spd**2),plotjoined=true,color='orange')
    plot.show(scale='loglog')
    
    plot = list_plot(zip(tfV[:,0],(tfV[:,2]-tfV[:,1])**2*D/spd**2),plotjoined=true,color='orange')
    plot.show(scale='semilogx')
    
    
