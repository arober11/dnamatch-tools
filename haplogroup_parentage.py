#!/usr/bin/env python
import json
import csv
import sys, getopt
import os

# Purpose:  Attempt to identiy the parents of a Haplogroup, in a tree
# 
# Authour: A. Roberts
# Date:    August 2023
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

hapDict={}
parDict={}

def script_usage():
  scrpt_name=os.path.basename(sys.argv[0])
  print('')
  print('Purpose:  Attempt to identiy the parents of a Haplogroup, in a tree')
  print('')
  print('Requires:')
  print('1: A haplotree in JSON format, generated by the like of the mtDNA-tree-to-all.sh, default: "mtDNA-tree-Build-17.json"')
  print('3: the name of the haplotree, within the JSON file, default "mt-MRCA(RSRS)"')
  print('')
  print('Usage: {} -h|--help -t|--treefl<haplogroup_file> -n|--name <haplotree_name> -g|-group <HaplogroupName>'.format(scrpt_name)) 
  print('e.g.')
  print('1: {} -t <haplogroup_file> -n <haplotree_name> -g <haplogroupcw>'.format(scrpt_name)) 
  print('2: {} --treefl=<haplogroup_file> --name=<haplotree_name> --group <haplogroup>'.format(scrpt_name))
  print('3: {} -h'.format(scrpt_name))
  print('4: {} --help'.format(scrpt_name))
  print('')
  print('e.g.')
  print('python ~/{} -t mtDNA-tree-Build-17.json -n "mt-MRCA(RSRS)" -g D'.format(scrpt_name))
  print('python3 ~/{} -treefl output/YDNA_ISOGG_Haplogrp_Tree.json -n "ISOGG-YDNA-BUILD-37" --group Q'.format(scrpt_name))
  print('python3 ~/{} -t YDNA_MINI_Haplogrp_Tree.json -n MINI-YDNA-BUILD-37 -g R1a'.format(scrpt_name))
  print('')


def search_tree(target, children):
  for haplogroup in children:
    if haplogroup['haplogroup'] == target:
      return haplogroup['haplogroup'] + '<-'
    else:
      if 'children' in haplogroup:
        resultStr=search_tree(target, haplogroup['children'])
        if resultStr != "":	
          return resultStr + haplogroup['haplogroup'] + '<-'
  return ""


def main(argv):
   json_tree_filename='mtDNA-tree-Build-17.json'
   tree_name='mt-MRCA(RSRS)'
   haplogroup=""

   try:
      opts, args = getopt.getopt(argv,"ht:n:g:",["treefl","treefl=","name","name=","group","group=","help"])
   except getopt.GetoptError:
      script_usage()
      sys.exit(2)
   for opt, arg in opts:
      if opt in ("-h","--help"):
         script_usage()
         sys.exit()
      elif opt in ("-t", "--treefl", "--treefl="):
         json_tree_filename = arg
      elif opt in ("-n", "--name", "--name="):
         tree_name = arg
      elif opt in ("-g", "--group", "--group="):
         haplogroup = arg

   if not os.path.isfile(json_tree_filename):
     script_usage()
     print('Error - Haplotree file does not exist')
     sys.exit()

   if tree_name == "":
     script_usage()
     print('Error - No non blank treename specified')
     sys.exit()

   if haplogroup == "":
     script_usage()
     print('Error - No non blank haplogroup specified')
     sys.exit()

   print('')
   print('Haplotree file: {}'.format(json_tree_filename))
   print('Tree name:      {}'.format(tree_name))
   print('Haplogroup:     {}'.format(haplogroup))
   print('')

   # Opening JSON haplogroup tree file
   with open(json_tree_filename, 'r') as haplogroup_tree_file:
     # Reading from json file
     json_object = json.load(haplogroup_tree_file)

   parentStr=(search_tree(haplogroup, json_object[tree_name]) + tree_name)
   if parentStr == tree_name:
     parentStr='NOT FOUND - check case'
   
   print('======================================================')
   print('')
   print('Parents of Haplogroup - ',haplogroup)
   print('')
   print(parentStr)
   print('======================================================')
   print('')

if __name__ == "__main__":
   main(sys.argv[1:])

quit()