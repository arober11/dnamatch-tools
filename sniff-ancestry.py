#!/usr/bin/env python3
# The above line helps ensure that python3 is used in this script, when running
# under Linux. You can also run it as "python <this script>" as long as your
# version of python is 3.x

# Grok the output from AncestryDNA web page to produce a match list CSV
#
# Run:
# - Check variables htmlfile and tester_csv below
# - Go to AncestryDNA match list, scroll to end of matches
# - Save page as... (same name as htmlfile below) by right-clicking
# - Run this program
# 
# Copyright 2021 Jef Treece
# Ok to use and modify for anything, but keep copyright in place
# Use at your own risk

# --- Things you may want to change ---

# The output of "save page as..." from AncestryDNA match list
htmlfile = '/tmp/A.html'

# The output file name
tester_csv = 'matches.csv'

# The separator between group names in the output csv file
group_sep = '|'

# Also save "cross matches" - if it's an in-common-with report?  NB: it's not
# possible to save amount of shared cM this way. E.g. if you're logged into kit
# "A", showing matches in common with "B" and you save_crossmatches, there will
# be an entry in the spreadsheet showing that "B" matches "C" but without any
# amount for shared cM.
# Set this to True or False.
save_crossmatches = True



# --- Usually, no changes are needed below this line ---

import csv, os, re, six, sys

# python2 will not work with this script, as likely there is no bs4 package you
# can get to run. If you have BOTH versions 2.x and 3.x installed, just make
# sure that you are running python3 for this script, and the bs4 module can be
# imported.
if six.PY2:
    print('This program requires Python 3.x, and you have Python 2.x.')
    print('Correct this issue by installing Python 3, then re-run.')
    print('Refer to https://www.python.org/downloads/')
    sys.exit(1)

# "pip install beautifulsoup4" may be needed (one-time setup), or in some
# installations, there may be an os package, such as "apt install python-bs4"
try:
    from bs4 import BeautifulSoup
except:
    print('This program requires the Beautiful Soup package.')
    print('You do not appear to have it installed.')
    print('Command: "pip install beautifulsoup4", then re-run')
    print('Refer to https://www.pythonforbeginners.com/beautifulsoup/beautifulsoup-4-python')
    sys.exit(1)

# field names in the output .csv
fieldnames = ['Kit1', 'Name1', 'Kit2', 'Name2', 'Manager',
                  'Shared cM', 'Note', 'Groups', 'URL']


# NB: the code is fragile, and will break if Ancestry changes page layout, HTML
# tags and variables. It should be easy to fix in most cases, since
# BeautifulSoup module does the heavy lifting. Open the raw html file and find
# the section and observe what tags are being used, then adjust below

outrows = []
with open(htmlfile, 'r') as rawhtml:
    soup = BeautifulSoup(rawhtml, 'lxml')

    # page title - whose matches are these
    # in page source, this looks like <h1 ...class="pageTitle">...</h1>
    description = ' '.join([s.strip() for s in soup.find('h1').strings])

    # handle either bare matches list or matches-in-common list
    if 'DNA Matches' in description:
        r = re.compile("(.*)'s DNA Matches")
        user1 = r.match(description).groups()[0]
        id1, id2 = None, None
    else:
        card = soup.find('compare-header')
        user1 = card.find('div', {'class': re.compile('compareUserLeft ')})['title']
        user2 = card.find('div', {'class': re.compile('compareUserRight ')})['title']
        btn = card.find('div', {'class': re.compile('addEditBtn')})
        url = (btn.find('a')['href'])
        id_re = re.compile('http.*guid1=([0-9A-Z-]+).*guid2=([0-9A-Z-]+)')
        id1, id2 = id_re.match(url).groups()


    # find all matches on the entire HTML page
    # in page source, each new match begins with <match-entry ...>
    for person in soup.find_all('match-entry'):

        # get note, if there is one
        # in page source, <p class="... notesText ..."> ... </p>
        try:
            notesText = person.find('p', {'class': re.compile('notesText ')}).string.strip()
        except AttributeError:
            notesText = ''

        # get shared DNA amount in cM
        # in page source, it's a <div> with class containing "sharedDnaText"
        # shared DNA is clickable, so it's inside a <button>
        # example "27 cM | < 1% shared DNA"
        shared_cm = ''
        dna = person.find('div',{'class':re.compile('sharedDnaText')})
        button = dna.find('button')
        cms = button.string.strip().split(' ')
        if cms[1] == 'cM':
            shared_cm = cms[0].replace(',', '')

        # get match's name and unique identifier for this match
        usr = person.find('a', {'class': re.compile('userCardTitle ')})
        match_name = usr.string.strip()

        # pick up the unique identifies used by Ancestry from the URL
        # the URL is clickable by prepending https://www.ancestry.com
        match_url = usr['href']
        ids = match_url.split('/')
        # unique identifier for the comparison kit
        match_id = ids[-1]
        # unique identifier for the kit owner
        kit_id = ids[-3]

        # which groups (color dots)?
        addl = person.find('div', {'class': re.compile('additionalInfoCol groupAreaDesktopStuff')})
        groupings = addl.find_all('span', {'class': re.compile('indicatorGroup ')})
        match_groups = []
        for grp in groupings:
            match_groups.append(grp['title'])

        # is the kit managed by someone?
        try:
            managed_by = person.find('div', {'class': re.compile('userCardSubTitle ')}).string.strip()
        except AttributeError:
            managed_by = ''

        # also save cross match (if in-common-with list)?
        if id2 and save_crossmatches:
            values = [id2, user2, match_id, match_name, managed_by, '', notesText,
                group_sep.join(match_groups), match_url]
            outrows.append({fieldnames[i]:values[i] for i in range(len(fieldnames))})
            
        # save the row to be output later
        values = [kit_id, user1, match_id, match_name, managed_by, shared_cm, notesText,
                      group_sep.join(match_groups), match_url]
        outrows.append({fieldnames[i]:values[i] for i in range(len(fieldnames))})

# save the result as a .csv
with open(tester_csv, 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames)
    writer.writeheader()
    writer.writerows(outrows)

print('Description: {}'.format(description))
print('Saved csv file {}'.format(tester_csv))
