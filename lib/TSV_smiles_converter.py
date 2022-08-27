import argparse
from rdkit.Chem import rdmolfiles

parser = argparse.ArgumentParser(description="Transform a space-separated SMILES file into a tab-separated SMILES file.")
parser.add_argument('-f','--file',metavar="File",required=True,type=str,help="a SMILES file to convert")

args = parser.parse_args()

print('\nTransforming file: {} \n\t into a tab-separated file.\n'.format(args.file))

try:
  mols = [m for m in rdmolfiles.SmilesMolSupplier(args.file,titleLine=0)]
  if mols[0] is None:
    raise Exception('Unable to read the file. Will still attempt to run the classification.')
  with rdmolfiles.SmilesWriter(args.file,includeHeader=False, delimiter='\t',nameHeader='') as f:
    for m in mols:
      if m is None:
        continue
      else:
        f.write(m)
  print('Your file is ready!')
except Exception as e:
  print('*** Error in reading the file')
  print(e)