
# Autonomy Organisation
#
# Handcrafted since 2022 by Autonomy Contributors <contact@autonomy.org>
#
# Configuration file for latexmk tool.

# -------------------------------------------------------------------------------------------------
# BASIC SETTINGS
# -------------------------------------------------------------------------------------------------

# Select 'lualatex' as default LaTeX engine (settings format since latexmk version 4.51)
$pdf_mode = 4;
$postscript_mode = $dvi_mode = 0;

# -------------------------------------------------------------------------------------------------
# GLOSSARIES
# -------------------------------------------------------------------------------------------------

add_cus_dep( 'acn', 'acr', 0, 'makeglossaries' );
add_cus_dep( 'glo', 'gls', 0, 'makeglossaries' );
$clean_ext .= " acr acn alg glo gls glg";

sub makeglossaries {
  my ($base_name, $path) = fileparse( $_[0] );
  my @args = ( "-q", "-d", $path, $base_name );
  if ($silent) { unshift @args, "-q"; }
  return system "makeglossaries", "-d", $path, $base_name; 
}

# -------------------------------------------------------------------------------------------------
# INDEX
# -------------------------------------------------------------------------------------------------

# Directives for building an index with 'latexmk' and 'xindy' (rather than 'makeindex')
add_cus_dep('idx', 'ind', 0, 'texindy');
sub texindy{
  system("texindy -L english \"$_[0].idx\"");
}

# -------------------------------------------------------------------------------------------------
# GIT METADATA
# -------------------------------------------------------------------------------------------------

# Extract Git metadata, such as the current branch, a tag, a release number and so on.
#
# This routine, rather than using a Git hook, as advocated by 'gitinfo2' author, is
# invoked by 'latexmk' so that to generate the '.git/gitHeadInfo.gin' file (as requested by
# 'gitinfo2' package).
#
# Credits: https://github.com/rbarazzutti/gitinfo2-latexmk/blob/master/gitinfo2.pm
sub git_info_2 {
    
    # get file content as a string
    my $get_file_content = sub {   
        my ($f)= @_;

        # do not separate the reads per line
        local $/ = undef;

        open FILE, $f or return "";
        $string = <FILE>;

        close FILE;
        return $string;
    };

    # compare two files contents
    my $cmp = sub {
        my($a,$b) = @_;

        return $get_file_content->($a) ne $get_file_content->($b);
    };

    my $RELEASE_MATCHER = "v[0-9]*.*";

    if(%GI2TM_OPTIONS){        
        if(exists $GI2TM_OPTIONS{"RELEASE_MATCHER"}){
            $RELEASE_MATCHER = $GI2TM_OPTIONS{"RELEASE_MATCHER"};
        }
    }

    my $GIN = ".git/gitHeadInfo.gin";
    my $NGIN = "$GIN.new";


    if(length(`git status --porcelain`) == 0){
        print "\nPackage latexmkrc-gitinfo2: Extract Git metadata to '.git/gitHeadInfo.gin'\n";

        # Get the first tag found in the history from the current HEAD
        my $FIRSTTAG = `git describe --tags --always --dirty='-*'`;
        chop($FIRSTTAG);

        # Get the first tag in history that looks like a Release
        my $RELTAG = `git describe --tags --long --always --dirty='-*' --match '$RELEASE_MATCHER'`;
        chop($RELTAG);

        # Hoover up the metadata
        my $metadata =`git --no-pager log -1 --date=short --decorate=short --pretty=format:"shash={%h}, lhash={%H}, authname={%an}, authemail={%ae}, authsdate={%ad}, authidate={%ai}, authudate={%at}, commname={%an}, commemail={%ae}, commsdate={%ad}, commidate={%ai}, commudate={%at}, refnames={%d}, firsttagdescribe={$FIRSTTAG}, reltag={$RELTAG} " HEAD`;
        
        # When running in a sub-directories of the repo
        my $dir = ".git";
        if (!(-e $dir) and !(-d $dir)) {
            mkdir($dir);
        }

        open(my $fh,'>',$NGIN);
        print $fh "\\usepackage[".$metadata."]{gitexinfo}\n";
        close $fh;  
    }else{
        print "Unclean Git repository.\n You should first commit pending modifications and run again.";   
    }

    $cmp->($GIN,$NGIN    );

    if((-e $GIN || -e $NGIN) && $cmp->($GIN, $NGIN)) {
            print "Status changed, request recompilation\n";
            $go_mode = 1;
            unlink($GIN);
            rename($NGIN, $GIN);
    } else {
        unlink($NGIN);
    }
}

git_info_2();
