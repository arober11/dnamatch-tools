# dnamatch-tools

Open-source tools providing capabilities for your DNA data from various DNA testing companies.

This project provides simple tools for working with various raw DNA and match list files for genetic genealogy.

Goals:
- open source license to promote sharing
- not dependent on a particular OS or platform
- community contributions accepted so it's not necessary to fork other projects
- provides capabilities that enhance or extend DNA matching

The typical user is expected to be able to find and install python, run run python from the command-line,
and locate and manipulate text files on the computer.

Notes for one-time setup and other hints can be found at the bottom of
this README, under **HELP and HINTS**.


## combine-kits.py:

**User story**: as a genetic genalogist who has tested at AncestryDNA, 23andMe and FTDNA,
I want to combine all of my data into a single data file that has the best coverage
possible from the available data for better matching and SNP overlap.

**User story**: as a tester at another company, I want to upload my data file to gedmatch,
but it's being rejected by gedmatch due to formatting or ordering or something.

**User skill required**: you will need to install python, clone or copy this source code,
find your data files on the computer, edit the file combine-kits.py, and run it from the command-line.

This script accepts raw data of autosomal tests from a few different autosomal testing companies
and combines it into one.

Another way to run it is with one kit instead of multiple ones.
By running it with just one test, certain problems may be fixed in the data.
In at least one case, the FTDNA data file could not be uploaded, but after
running this program, the output file uploaded OK. The main thing it "fixed"
was the chromosome ordering within the file.

The reason for combining kits is each testing company gets a slightly different
coverage of the DNA, which may also depend on when you tested,
since occasionally testing companies switch to different testing technology.

Comparing your results with someone else from the same testing company,
using the same testing technology, will not be improved significantly by combining test results.
However, comparing your results with someone who tested at a different company or whose results
came from a different testing technology, will likely be improved because there will be more
SNPs that can be compared.
The end result may mean more-relevant matches and better definition of the end-points
of the overlapping DNA segments.

To use the combined file, it can be read into a spreadsheet, manipulated as text other ways, or uploaded
to a DNA match service such as gedmatch.

**Usage**: refer to comments in the script

## phase-kit.py:

**User story**: I have autosomal DNA results for both of my parents, and
I want to determine which allele came from which parent so I can do more-precise
matching and mapping.

**User skill required**: you will need to install python, clone or copy this source code,
find your data files on the computer, edit the file phase-kit.py, and run it from the command-line.

This script accepts raw data of autosomal tests from a few different autosomal testing companies. The files may be compressed (.zip or .csv.gz) or uncompressed.
It currently requires a child, mother and father data and does not yet try
to phase if only one parent is available.

The data files may also be combined kits, produced by combine-kits.py.

For a given location to be phased, both parents must have values at that location. Locations that are missing a parent's data are rejected and not written to the output. Uncertain locations (where it's impossible to determine which parent contributed which allele) are also rejected.

The output is a .csv to be read into a spreadsheet.

**Usage**: refer to comments in the script


## extend-kit.py:

**User story**: I have autosomal DNA results for me and both of my parents, and
I want to utilize their data to fill in new positions in my own kit
to make my kit better for matching.

**User skill required**: you will need to install python, clone or copy this source code,
find your data files on the computer, edit the file extend-kit.py, and run it from the command-line.

This script accepts raw data of autosomal tests from a few different autosomal testing companies. The files may be compressed (.zip or .csv.gz) or uncompressed.
It currently requires a child, mother and father data.

The data files may also be combined kits, produced by combine-kits.py.

For an allele at a given location of a chromosome to be deduced for the child, both parents must have values at that location, and both parents must be homozygous at that location. The output consists of the union of the original positions the child had and the additional values that can be determined from the parents.

The output is a .csv to be read into a spreadsheet or uploaded to a matching service such as gedmatch.

**Usage**: refer to comments in the script


## sniff-ancestry.py:

**User story**: As a genealogist using DNA matches, I would like a
list of my matches from AncestryDNA in a spreadsheet so I can keep
better track, history and notes.

**User story**: I have AncestryDNA matches that I want to pull out
into a spreadsheet for match and network analysis with graphviz,
gephi and other tools, yet I don't see any way to do that from the
web page platform. Help!

**User story**: I have seen some spreadsheet methods that use
cut-and-paste of AncestryDNA matches into a spreadsheet with macros
and formulas, but I would like a programmatic way of generating my
spreadsheet that I can understand.

**User skill required**: you will need to install python, clone or
copy this source code, log into your AncestryDNA account, save the web
page of interest from your AncestryDNA matches (right click, then save
the full web page as a .html file), find the file you saved on the
computer, edit the file sniff-ancestry.py to make sure a few variables
are set correctly, and run it from the command-line. The script
requires the package "lxml" and the package "beautiful soup", so as a
one-time setup, you may need to run the commands "pip install lxml"
and "pip install beautifulsoup4"

This script takes raw web-page data that you can save from your
browser when looking at your match list, and it parses that data into
a match list that it saves in a .csv spreadsheet file. This file can
be opened with LibreOffice or any other spreadsheet that can read a
.csv file. The html file would normally look like "gobly gook" because
it's not meant to be read by a human. It's meant to be read by a web
browser. Sniff-ancestry.py turns it into something usable.

**Usage**: There are about four settings that can be modified in the script.
Check those before running.

First, bring up a match list, and scroll down to load as many matches
as you wish. Then right click on the page and "save page as..." or use
some other method to capture the page source into a file. If you have
a choice how to save, use the full web page option. It may produce a
folder with a lot of separate files and a separate .html file with the
name as you chose in saving it. Ignore the folder. You can remove it
if you want. You just need the .html file.

NOTE: you probably won't have much success trying to save all of your
matches in one go. It's recommended that you break up the list into
manageable sizes, either by filtering on a range of shared DNA or
filtering on a surname or other criteria. There may be 50,000 or more
people in the full match list, and if it works at all, it will be very
slow if you try to do it all at once.

Saving the file can typically be done by a right-click on the web
page, but the specific instructions may depend on which browser you're
using. As long as you can save it as a complete .html file, it should work.

Make sure that file matches the file name in the script, or adjust accordingly.

Next, run the script, and find the output in the .csv file it creates.

Refer to other comments in the script


## ff-matchgraph.py:

**User story**: I have match lists for a number of my relatives in
multiple spreadsheets, and I would like to generate a database and
edges and nodes from these combined matches to study matches in common
between the testers

This code is in alpha stage. It probably works as described, but refer
to comments in code, and your mileage may vary. Please provide feedback.


## cluster-segments.py:

**User story**: I have a list of segments matched for a given tester,
and I want to study which sections of each chromosome got the most
matches so I may have some additional information for chromosome
mapping.

**User skill required**: you will need to install python, clone or copy this source code,
find your data files on the computer, edit the file cluster-segments.py (optional),
and run it from the command-line.

This code produces a histogram for each chromosome. The histogram
represents how many segment matches occur at that place on the
chromosome. There are many uses for visualizing the chromosomes in
this manner. For example, it can reveal areas of the chromosomes that
are "hot" such that many matches occur at those areas.

The input segments are one or more spreadsheets as .csv files that
have, at least, a chromosome number, a starting position and an ending
position. These are the only three columns used in creating the
histograms. The .csv file may be from anywhere, as long as it contains
the three columns. For example, various segment lists can be exported
at gedmatch, or at most testing companies.

Sample output:

![cluster-segments](/screenshots/cluster-segments-sample.png?raw=true "Sample output from cluster-segments")

This code is in alpha stage. It probably works as described, but refer
to comments in code, and your mileage may vary. Please provide feedback.


## merge-csv.py:

**User story**: I've pulled a bunch of DNA matches into multiple
spreadsheets, and I would like to combine those spreadsheets into one
file, with duplicates removed so I can use the de-duplicated rows as
input into another program.

**User skill required**: you will need to install python, clone or
copy this source code, and run it as a python program

This script takes multiple .csv files and combines them into one file
that has duplicate rows removed.  Each .csv file must have identical
columns for the merge to take place. Non-identical .csv files are
ignored.

**Usage**: There are no settings. Run the program with all of the file
names you want to merge, plus the output file (final filename) on the
command line.

Example: merge-csv.py a.csv b.csv c.csv out.csv


## HELP and HINTS

Almost everything here will require that you have python
installed. Python is a free and open source programming language, and
it's used to run these programs. Don't be afraid! Installation is
typically very easy. It can be installed on various platforms, so it
doesn't matter if you're running Windows, Linux, or something else.
The precise installation instructions may vary a bit between different
platforms. A few tips to get you started are presented in this help
section. **Do this once** then afterwards, you will have Python
installed.

Python has been around for a long time, and there are more than one
version. Generally, you should **install version 3** (the version
number begins with 3.) if that is available to you.

Any python installation normally also installs a program called
"pip". When other software packages are needed here, the normal way to
do it is by typing the command "pip install <package>". Again, this is
a one-time step. Once you've done it, you're good to go on runnng
these programs.

**Windows** installation of Python has been covered by so
many people previously that there's no reason for us to re-invent
instructions. Watch one of these videos or tutorials, or simply use your search
engine to find your favorite installation instructions:
- https://www.tutorialspoint.com/how-to-install-python-in-windows
- https://www.youtube.com/watch?v=uDbDIhR76H4
- https://www.youtube.com/watch?v=i-MuSAwgwCU
- https://www.youtube.com/watch?v=UvcQlPZ8ecA

**Linux** installation of Python varies a bit, depending on which
distribution of Linux you are running. Use your favorite package
manager to install it, or use something along the lines of "apt
install python" if you're using command-line and a Debian-based Linux.

**MacOS** installation and validation of Python installation is covered here:
- https://www.youtube.com/watch?v=TgA4ObrowRg

**Other platforms** - no installation instructions are provided
here. You will need to find the appropriate installation instructions
for your OS by searching with a search engine, downloading the
appropriate software and following the instructions. Feel free to
provide the instructions which can be added to this readme file.

**After installing Python**

Installation of Python is done one-time, before trying to run any
programs. Along with the installation of Python, you will likely need
to install a couple of packages. Go ahead and run these commands from
a command prompt after installing python:
- pip install lxml
- pip install beautifulsoup4

**Python versions**

It's possible you have python installed already. In a command window,
type the command "python --version". If it returns with a version
number, it means you have python installed. You should also be able to
see the pip version by running the command "pip --version"

The preferred python version is any number that begins with "3.".

If you have multiple versions of python, and the default is not 3.x,
you can run specifically the correct versions of python and pip by
running the commands "python3" and "pip3". You should ensure that
these are the versions you are running for the programs here.

## lookup_Haplogroup.py 

Purpose:  Attempt to identiy possible haplogroups, based on the mtDNA/yDNA SNPS from a genotype file generated by the large to customer providers, or a combined file

Requires:
1: A haplotree in JSON format, generated by the like of the mtDNA-tree-to-all.sh, default: "mtDNA-tree-Build-17.json"
2: A set of SNPS (position,call), in a CSV file, to compare against the haplotree; can be generated by the like of:
  - mDNA_file_SNPS_in_Haplotree.sh
  - YDNA_file_SNPS_in_Haplotree.sh
3: the name of the haplotree, within the JSON file, default "mt-MRCA(RSRS)"

Usage:
 lookup_Haplogroup.py -s  <SNP_file> [-t <haplogroup_file> -n <haplotree_name>]

 lookup_Haplogroup.py -snpfl=<SNP_file> [--treefl=<haplogroup_file> --name=<haplotree_name>]

 lookup_Haplogroup.py -h

 lookup_Haplogroup.py --help

e.g.
python ~/lookup_Haplogroup.py -s mtDNA_SNPS_combined.csv  -t output/mtDNA-tree-Build-17.json -n "mt-MRCA(RSRS)"
python ~/lookup_Haplogroup.py -snpfl=some_YDNA.csv -treefl=output/YDNA_ISOGG_Haplogrp_Tree.json -n "ISOGG-YDNA-BUILD-37"

**Usage**: refer to comments in the script, and see example output in the output folder

## DNA_file_state.sh		

Indicates the SNPS per chromosome in an autosmal file from the like of Ancestry, 23AndMe, FTDNA, ... , or a combined file
Along with counts of the CALLS and NO CALLS per chromosome

Usage:   DNA_file_state.sh <rawfile[.txt|.csv]> [,]

Purpose: Reports SNP counts, per chromosome, with a count of calls, and no calls.

defaults: 
  rawfile = AncestryDNA.txt
  deliminator  = tab (AncestryDNA)

Nb: To use the with a FTDNA raw file, sepcify a deliminator of ',' withoug (the quotes).

**Usage**: refer to comments in the script, and see example output in the output folder

## DNA_file_mtDNA_diff.sh		

Compares the mtDNA SNPS between two autosmal files, be they from Ancestry, 23AndMe, FTDNA, ... , or a combined file
Indicating if the SNPS present in BOTH files match or differ

Usage:   DNA_file_mtDNA_diff.sh <rawfile1[.txt|.csv]> <rawfile2[.txt|.csv]> [M|Missing]

Purpose: Diff the mtDNA calls between two DNA files.

Opions - [M|Missing]  - List SNPS in one file but not the other

defaults: 
  rawfile = DNA1.txt
          = DNA2.txt

**Usage**: refer to comments in the script

## DNA_file_YDNA_diff.sh

Compares the YDNA SNPS between two autosmal files, be they from Ancestry, 23AndMe, FTDNA, ... , or a combined file
Indicating if the SNPS present in BOTH files match or differ

Usage:   DNA_file_YDNA_diff.sh <rawfile1[.txt|.csv]> <rawfile2[.txt|.csv]> [M|Missing]

Purpose: Diff the YDNA calls between two DNA files.

Opions - [M|Missing]  - List SNPS in one file but not the other

defaults: 
  rawfile = DNA1.txt
          = DNA2.txt

**Usage**: refer to comments in the script

## get_YDNA_rsid.sh

Download the latest ISOGG YDNA SNP list,
          Correct for a few anomalies in the list,
          Extract the rsid names, mutation names and the Build 37 SNP positions to a series of files:
            - YDNA_SNPS.csv - downloaded file with any:
               -- '#REF!' swapped for C1a2b1b2
               -- A9832,2 swapped for A9832.2
               -- ; removed
               -- 'Notes' blanked
               -- Haplogroup names with a spave between the name and a '~' suffix removed
               -- 'Freq. Mut. SNP in ' removed from Haplogroup names
            - Outputs:
              -- YDNA_SNPS.csv                               - Downloaded file with above alterations
              -- YDNA_rsid_mutations-Build37.csv             - list of rsid names in file, e.g.
                rs,numbers
                rs1000104620,G->A
                rs1000104755,C->A
                ...
              -- YDNA_rsid_muts-Build37.csv                  - list of rsids, with mutation and mutation name used, e.g.
                rs,numbers,Name
                rs1000104620,G->A,Z12464
                rs1000104755,C->A,FGC1864
                rs1000104755,C->A,Y2087
                ...
              -- YDNA_HAPGRP-Build37.SNP_Positions_used.txt  - list of Y chromosome, build 37, range expanded, positions used e.g.
                10000350
                10000477
                10000888
                ...
              -- YDNA_HAPGRP_muts-Build37.csv                - list of muations use in a hybrid CSV and JSON format, eg.
                A,"mutations":[{"posStart":"14814060","ancestral":"G","descendant":"C","type":"0","display":"G14814060C","label":"M171","alias":"CTS10804"},
                               {"posStart":"21868776","ancestral":"A","descendant":"C","type":"0","display":"A21868776C","label":"M59","alias":"CTS1816"},
                               {"posStart":"6851661","ancestral":"C","descendant":"T","type":"0","display":"C6851661T","label":"L1100","alias":"V1143"}]
                  A0,"mutations":[{"posStart":"14001289","ancestral":"G", ...
              -- YDNA_HAPGRP_muts-Build37.json               - above file in just JSON format, e.g.
                [{"haploGrp":"A","mutations":[{"posStart":"14814060","ancestral":"G","descendant":"C","type":"0","display":"G14814060C","label":"M171","alias":"CTS10804"},
                                              {"posStart":"21868776","ancestral":"A","descendant":"C","type":"0","display":"A21868776C","label":"M59","alias":"CTS1816"},
                                              {"posStart":"6851661","ancestral":"C","descendant":"T","type":"0","display":"C6851661T","label":"L1100","alias":"V1143"}]}
                ...
                ]

Notes 
      - AncestryDNA v2 + 23AndMe v5 appear to use the Build 37 positions
      - Mutation code types output
       type 0     - transitions    - upper case (e.g., G->A)
       type 3     - deletions      - “del”
       type 4     - insertions     - "ins"

**Usage**: refer to comments in the script

## dup_RSID_names.sh		

Identifies the SNPS that are reported under multiple names in an autosmal file the like of Ancestry, 23AndMe, FTDNA, ... , or a combined file

Usage:   dup_RSID_names.sh <rawfile1[.txt|.csv]> 

Purpose: Identify the duplicate RSID names in a genotype file.

**Usage**: refer to comments in the script

## mtDNA_file_SNPS_in_Haplotree.sh

Identifies the mtDNA SNPS from a Ancestry, 23AndMe, FTDNA, ... , or combined file that are common with those of a mtDNA HaploTree, and those not in the tree.

Usage:   mtDNA_file_SNPS_in_Haplotree.sh <rawfile1[.txt|.csv]> [<mtDNA-tree-Build-##_SNP_Positions_used.txt>]

Purpose: lookup mtDNA calls from an autosomal DNA file and a published mtDNA haplotree

defaults: 
  rawfile  = DNA1.txt
  treefile = mtDNA-tree-Build-17.SNP_Positions_used.txt

outputs: 
  rawfile-mtDNA-snps = <rawfile1>_mtDNA           - mtDNA data as it appeared in the rawfile
  rawfile-mtDNA-snps = <rawfile1>_mtDNA.SNPS.txt  - mtDNA SNP list from the rawfile
  rawfile-mtDNA-snps = <rawfile1>_mtDNA.SNPS.csv  - mtDNA SNP calls from the rawfile

**Usage**: refer to comments in the script, and see example output in the output folder

## YDNA_file_SNPS_in_Haplotree.sh	

Identifies the YDNA SNPS from a Ancestry, 23AndMe, FTDNA, ... , or combined file that are common with those of a YDNA HaploTree, and those not in the tree.

Usage:   YDNA_file_SNPS_in_Haplotree.sh <rawfile1[.txt|.csv]> [<YDNA-tree-Build-##_SNP_Positions_used.txt>]

Purpose: lookup YDNA calls from an autosomal DNA file and a published YDNA haplotree

defaults: 
  rawfile  = DNA1.txt
  treefile = YDNA_HAPGRP-Build37.SNP_Positions_used.txt

outputs: 
  rawfile-YDNA-snps = <rawfile1>_YDNA           - YDNA data as it appeared in the rawfile
  rawfile-YDNA-snps = <rawfile1>_YDNA.SNPS.txt  - YDNA SNP list from the rawfile
  rawfile-YDNA-snps = <rawfile1>_YDNA.SNPS.csv  - YDNA SNP calls from the rawfile

See: get_YDNA_rsid.sh for obtaining the SNP position list

**Usage**: refer to comments in the script

## mtDNA-tree-to-all.sh	

Covert one of the phylotree.org mtDNA Haplotree HTML pages into a series of txt, csv, and json files.	

Extracting the mtDNA Haplogroup names as a text file, the unique mutations from the Revised Cambridge / Sapien sequence, and reformat the Webpage to both a CSV and JSON file
Source page: https://www.phylotree.org/builds/mtDNA_tree_Build_17.zip

Requires: GNU perl + GNU sed + GNE egrep

Notes:
 - Partially hacked together on MacOS 10.13.6 using the bundeled POSIX (BSD), rather than GNU utilites, but hit issues with the mixed ASCII, UTF-8 and HTML escape chars in the source HTML file, now tweaked so use the GNU variants of sed and egrep.
 -- An abort with a count error will likley be down to an unexpected, escaped character in the HTML
 - Novel convention - The Tree contains ANONYMOUS precursor mutations, to a set of one or more Haplogroups, that have no haplogroup label themselves eg.
 -- Parent Haplogroup: H2a1 [ G951A  C16354T]
    -- Precursor: [T146C!]
       -- Child: H2a1n [G4659A]
 To simplify downstream scripts the ANONYMOUS precursor mutation sets are given a hybrid label comprised of their parent and first chile with a "@" delimitor inserted, e.g. 
   H2a1 to H2a1n precursor set will be labelled "H2a1@n" in the CSV and JSON output files.

 - To make the JSON more readable there are numerous beautifiers, like:
    python -m json.tool mtDNA-tree-Build-*.json

Usage:   mtDNA-tree-to-csv.sh [<mtDNA-tree-Build-##.htm>]

Purpose: Extract the mtDNA Haplogroup names as a text file and the assosiated mutations from the Revised Cambridge / Sapienb sequence as a JSON file
          - Source file:  https://www.phylotree.org/builds/mtDNA_tree_Build_17.zip

defaults: 
  Input-mtDNA-tree-Build-file  = mtDNA-tree-Build-17.htm
  output-Haplogroup-Names-file = mtDNA-tree-Build-17_Haplogroups.txt
  output-Haplogroup-Mutiaions  = mtDNA-tree-Build-17_mutations.csv
  output-mtDNA-Haplogroup-JSON = mtDNA-tree-Build-17.json

**Usage**: refer to comments in the scrip, and see example output in the output folder

## get_YDNA_trees.sh

Purpose: Attempt to download and combine and convert the ISOGG YDNAi tree files from https://isogg.org/tree/index.html

    - Outputs: 
      - YDNA_ISOGG_Haplogrp_Tree.A.csv through YDNA_ISOGG_Haplogrp_Tree.T.csv and YDNA_ISOGG_Haplogrp_Tree.TRUK.csv  
        -- downloaded Google sheets
        -- with notes, comments and severl inconsistencies removed.
      - YDNA_ISOGG_Haplogrp_Tree.haplogrps.txt       - list of YDNA haplogroup names use, e.g.d
       Y
       A0000
       A000-T
       A000
       A000a
       A000b
       A000b1
       A00-T
       A00-T~
       A00
       ...
      - YDNA_ISOGG_Haplogrp_Tree.TRUNK.csv           - haplogroup names and mutations indented to reflect tree structure, e.g.
        Y,Root (Y-Adam),,,,,,,,,,,,,,,,,,,,,,
        ,A0000,A8864,,,,,,,,,,,,,,,,,,,,,
        ,A000-T,A8835,,,,,,,,,,,,,,,,,,,,,
        ,,A000,A10805,,,,,,,,,,,,,,,,,,,,
        ,,A00-T,PR2921,,,,,,,,,,,,,,,,,,,,
        ,,,A00,AF6/L1284,,,,,,,,,,,,,,,,,,,
        ,,,A0-T,L1085,,,,,,,,,,,,,,,,,,,
        ,,,,A0,CTS2809.1/L991.1,,,,,,,,,,,,,,,,,,
        ,,,,A1,P305,,,,,,,,,,,,,,,,,,
        ,,,,,A1b,P108,,,,,,,,,,,,,,,,,
        ...
      - YDNA_ISOGG_Haplogrp_Tree.merged.csv          - haplogroup names indented to reflect tree structure, e.g.
        Y
        ,A0000
        ,A000-T
        ,,A000
        ,,,A000a
        ,,,A000b
        ,,,,A000b1
        ,,A00-T
        ,,A00-T~
        ,,,A00
        ,,,,A00a
        ,,,,A00b
        ,,,,A00c
        ,,,A0-T
   - AncestryDNA v2 + 23AndMe v5 appear to use the Build 37 positions
   - TAKES and age - as made up as I ran into each inconsistency in the file, and processed in a manner the issue could be coded around (Needs a rewrite in Perl / Python)

 Notes:
   - Source Google sheets have a growing collection of comments / annotations, along with some unhelpful / incosistent foratting, that needs to be removed, 
     as will blow the script
   - requires the outut of 'get_YDNA_rsid.sh'
   - Output JSON mutation type:
    type 0     - transitions    - upper case (e.g., G->A)
    type 3     - deletions      - “del”
    type 4     - insertions     - "ins"
   - the 'YDNA-tree-to-all.sh' script will attempt to convert the output from this script and the 'get_YDNA_rsid.sh' script into a single JSON file

**Usage**: refer to comments in the scrip, and see example output in the output folder

## YDNA-tree-to-all.sh

 Purpose: Attempt to combine and convert the ISOGG YDNA files from https://isogg.org/tree/index.html

Note:
   - Source Google sheets have a growing collection of comments / annotations, along with some unhelpful / incosistent foratting, that needs to be removed,
      as will blow the script
   - the 'get_YDNA_trees.sh' and 'get_YDNA_rsid.sh' scrpts will attempt to download, strip and merge the ISOGG sheets into something usable by this script.
   - AncestryDNA v2 + 23AndMe v5 appear to use the Build 37 positions
   - TAKES and age - as made up as I ran into each inconsistency in the file, and processed in a manner the issue could be coded around (Needs a rewrite in Perl / Python)

   - Output 
     -- Y-Haplogroup tree, build 37, in JSON format, e.g.
     {"ISOGG-YDNA-BUILD-37":[
       {"haplogroup":"Y","children":[
         {"haplogroup":"A0000","mutations":[
           {"posStart":"10016359","ancestral":"G","descendant":"A","type":"0","display":"G10016359A","label":"A8897","alias":"Y19091"},
           {"posStart":"10042663","ancestral":"G","descendant":"C","type":"0","display":"G10042663C","label":"A8898","alias":"Y19091"},
     ..
         }]
       }]
     }

Notes:
   - requires the outut of 'get_YDNA_rsid.sh'
   - Output JSON mutation types:
    type 0     - transitions    - upper case (e.g., G->A)
    type 3     - deletions      - “del”
    type 4     - insertions     - "ins"

**Usage**: refer to comments in the scrip, and see example output in the output folder

## to_AncestryFromat.sh

Reformat a combined file, or one of the other formats, into something thatlooks a bit like an AncestryDNA file, to use elsewhere.
Usage:   to_AncestryFromat.sh <combined_file.csv> [<outputAncestryFromatFileName> [<outputAncestryFromatArchive>]]

Purpose: Reformats, and packages the atDNA combined output CSV file, in AncestryDNA v2 format; to humour utilities that expect that format.

defaults: 
  outputAncestryFromatFileName = AncestryDNA.txt
  outputAncestryFromatArchive  = 

**Usage**: refer to comments in the script
