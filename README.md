### _RegOpHrs.pl_
# Regional open hours analysis for Cabrillo contest logs
Listing the number of QSOs each one half hour for 
specific groups of countries

rin fukuda, jg1vgx@jarl.com, Feb 2006
ver 0.02

Requirements
------------
You need Perl package to run this script. If you are on Windows, use ActivePerl (http://www.activestates.com/). 

How to Use
----------
1. Perl module _Date::Simple_ is required. Use Perl Package Manager of ActivePerl to install it.

2. Files required in the program directory.
    - _Log to be analysed, in Cabrillo format_. QSO data must be listed in chronological order.
    - _cty.dat_ ... get the newest one from http://www.k1ea.com/
    - _Country or regions of interest list file_. A sample is included as dest.cty. Each line correspond to a region to be analysed. The word in the first column ending in colon(:) is an index name for output file. This could be anything but limited in only three letters. There after you can list any number of country prefixes in that line each separated by a space. You can specify one of EU, AF, NA, SA, AS, OC as referring to all countries in that continent. To do so, prepend the continent shotcut with '='. You can also specify particular countries to be removed from the selection. For example, if you need EU but UA and UA2, you can list them as "=EU -UA -UA2".

3. Run the script. You will be asked the file name of Cabrillo log and regions of interest file. Also, the starting and ending date and time will be asked. It is something like 2006-03-25 and 0000 or 2359. Then program starts to analyse but it takes considerable time to finish all the analysis.

4. Results will be created in a file "result.txt" in the directory.

Version History
---------------
v0.02 (28 Feb 2006)
- Bug fix
- accept "-UA" like format for exclusion of a prefix

v0.01 (27 Feb 2006)
- First Release
