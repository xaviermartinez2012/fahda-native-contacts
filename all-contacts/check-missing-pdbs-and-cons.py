import sys
import os
import re

def nastySplit(pdb):
    frameNumber = int(pdb.split('_')[-1].split('.')[0])
    return frameNumber

# First argument of command execution is the project directory 
projDirectory = sys.argv[1]

# Checks if the user inputs the project directory
if(not projDirectory):
    print("Project directory is missing from command.")

# Deletes "/" if appended to project directory string
projDirectory = re.sub('\/', '', projDirectory)
## print(projDirectory)
### PROJ1797

# Grabs the file path of the current directory
currentDirectory = os.getcwd()
## print(currentDirectory)
### /home/jnguyen/Scripts

# Get project directory path
projDirectoryPath = os.path.join(currentDirectory, projDirectory)
## print(projDirectoryPath)
### /home/jnguyen/Scripts/PROJ1797

for dirPath, _ , files in os.walk(projDirectoryPath):
    # If there are no files in the directory, then skip
    if not files:
        continue
    print('\ndirPath:',dirPath)
    print('files:',files)
    # Grabs all pdb files and put them in a list
    pdbFiles = [pdb for pdb in files if '.pdb' in pdb]
    if not pdbFiles:
        print("No pdb files in", dirPath)
        continue
    else:
        pdbPrefix = re.sub(r'\d*\.pdb','{}.pdb', pdbFiles[0])
        conPrefix = re.sub(r'.pdb', '.con', pdbPrefix)
    counter = 0
    for file in files:
        #print('counter:',counter)
        if '.con' in file:
            #print('conFile:',file)
            #print('pdbFile:', pdbFiles[counter])
            if re.sub(r'.pdb','',pdbFiles[counter]) not in file:
                print('\nCon file missing for %s \n' % pdbFiles[counter])
            counter+=1
    #print('pdbFiles:',pdbFiles)
    frameNumbers = list()
    for pdb in pdbFiles:
        match = re.findall(r'\d*\.pdb', pdb)
        #print('match:', match)
        frameNumbers.append(int(re.sub(r'.pdb', '', match[0])))
        #print('frameNumbers:', frameNumbers)
        #print('sortedFrameNumbers:', sortedFrameNumbers)
    sortedFrameNumbers = sorted(frameNumbers)
    missingFrames = [ frame for frame in list(range(0, sortedFrameNumbers[-1]+1)) if frame not in sortedFrameNumbers]
    for frame in missingFrames:
        print("Missing", pdbPrefix.format(frame))