# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from os import listdir
from os.path import isfile, join  

# Create empty DataFrame to collect results
row_titles = ['Name', 'Z_MAX', 'ZPos_MAX', 'ZPos_upperlimit', 'ZPos_lowerlimit', 
              'Diam_MAX', 'DiamPos_MAX', 'DiamPos_upperlimit', 'DiamPos_lowerlimit',
              'Zlumen_MAX', 'Zlumen_MAX', 'Zlumen_upperlimit', 'Zlumen_lowerlimit',
              'DiamLumen_MAX', 'DiamLumen_MAX', 'DiamLumen_upperlimit', 'DiamLumen_lowerlimit']
resultsFWHM = pd.DataFrame(columns=row_titles)

# Function to measure signal intensity of protein of interest (POI) using IntDen plot of averaged basal body.
# Variables: df = DataFrame with Intensity profiles of POI; Name = POI name; rad = radius to define lumen of basal body, default 18 px; column_start and column_end = start and end of column if POI has multiple positions, default None.
def FWHM(df,Name,rad=18, column_start = None, column_end = None):
    row_results = [0, 0, 0, 400, 400, 0, 0, 400, 400, 0, 0, 400, 400, 0, 0, 400, 400]
        
    print ("working on: " + Name[0:-4])

    row_results[0] = Name[0:-4]
    nRows = len(df.axes[0])
    nCols = len(df.axes[1])
    
    
    # Range of columns to measure. In default, all columns are measured. If POI has multiple positions seperated in z, measurements are performed on subset of columns. Range can be adjusted using column_start and column_end. 
    if column_start == None:
        column_start = 0
    else:
        nCols = nCols - column_start
        
    if column_end == None:
        column_end = nCols
    else:
        nCols = nCols - column_end
    
    
    df2 = df.iloc[:, column_start+1:column_end]
    df2.insert(0, "X0", df.iloc[:,0])
    df=df2


    # Proteins outside lumen
    # FWHM z-axis: Calculation of sum IntDen of all rows and determination of max IntDen, the position of max IntDen, and position where IntDen is 1/2 of max IntDen, termed upper and lower limit.
    sumRows = df[rad:].sum()            # [:] determines start and finish of region in which max is searched. Default [18:]
    sumRows[0] = 0
    sumRows.name = 'sum'
    df = df.append(sumRows.transpose())

    Z_MAX = df.loc['sum'].max()      
    row_results[1] = Z_MAX  
    ZPos_MAX = df.max().idxmax()   
    row_results[2] = int(ZPos_MAX[1:])
        
    for i in range(1,nCols-1):
            r = i-1
            max_temp = (df.loc['sum'][i])
            if max_temp >= (0.5*Z_MAX) and r <= row_results[4]:
                row_results[4] = r
            elif max_temp >= (0.5*Z_MAX):
                    row_results[3] = r
            
    # FWHM xy-axis 'diameter': Calculation of sum IntDen of all columns in row with max IntDen and determination of max IntDen, the position of max IntDen, and position where IntDen is 1/2 of max IntDen, termed upper and lower limit.
    temp = df.loc[:,ZPos_MAX]
    Diam = temp[rad:-1]                 # [:] determines start and finish of region in which max is searched. default [18:-1]

    Diam_MAX = Diam.max()
    row_results[5] = Diam_MAX
    DiamPos_MAX = Diam.idxmax() + 1
    row_results[6] = DiamPos_MAX
        
    for i in range(rad,nRows):        # range(18,nRows) determines start and finish of region in which max is searched. default
            r = i-1
            max_temp = (Diam[i])
            if max_temp >= (0.5*Diam_MAX) and r <= row_results[8]:
                row_results[8] = r
            elif max_temp >= (0.5*Diam_MAX):
                    row_results[7] = r
        
    # Proteins inside lumen
    # FWHM z-axis: Calculation of sum IntDen of all rows and determination of max IntDen, the position of max IntDen, and position where IntDen is 1/2 of max IntDen, termed upper and lower limit.
    sumRows = df[:rad].sum()
    sumRows[0] = 0
    sumRows.name = 'sumlumen'
    df = df.append(sumRows.transpose())

    Zlumen_MAX = df.loc['sumlumen'].max()      
    row_results[9] = Zlumen_MAX    
    ZlumenPos_MAX = df.max().idxmax()   
    row_results[10] = int(ZlumenPos_MAX[1:])
        
    for i in range(1,nCols-1):
            r = i-1
            max_temp = (df.loc['sumlumen'][i])
            if max_temp >= (0.5*Zlumen_MAX) and r <= row_results[12]:
                row_results[12] = r
            elif max_temp >= (0.5*Zlumen_MAX):
                    row_results[11] = r
            
    # FWHM xy-axis 'diameter': Calculation of sum IntDen of all columns in row with max IntDen and determination of max IntDen, the position of max IntDen, and position where IntDen is 1/2 of max IntDen, termed upper and lower limit.
    temp2 = df.loc[:,ZlumenPos_MAX]
    Diamlumen = temp2[0:rad]

    Diamlumen_MAX = Diamlumen.max()
    row_results[13] = Diamlumen_MAX
    DiamlumenPos_MAX = Diamlumen.idxmax() + 1
    row_results[14] = DiamlumenPos_MAX
        
    for i in range(1,rad):
            r = i-1
            max_temp = (Diamlumen[i])
            if max_temp >= (0.5*Diamlumen_MAX) and r <= row_results[16]:
                row_results[16] = r
            elif max_temp >= (0.5*Diamlumen_MAX):
                    row_results[15] = r
    return row_results, df

#Append results df with new information
path = r"F:\Basal body averaging 2024\Analysis\Validation diameter\20241106\Raw intDen AKNA test\\"
file_list = [f for f in listdir(path) if isfile(join(path, f))]


# if no additional argumens are given to FWHM() definition, there will be selection for luminal at radial postion 18 and all columns will be included
for file in file_list:
    if '.csv' in file:
        df = pd.read_csv(path + file)
        row_results = FWHM(df,file,35,None,None)
        resultsFWHM.loc[len(resultsFWHM)] = row_results[0]
        df2 = row_results[1]
        
resultsFWHM.to_csv(r'F:\Basal body averaging 2024\Analysis\Validation diameter\20241106\ResultsFWHMdiam18_V10.csv') 


