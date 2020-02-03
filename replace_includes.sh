gawk -i inplace -vFPAT='([^ }{]+)|(\"[^\"]+\")' '
	{INDENT="  "} /^  include:/{m=$0} !m{ print } m{
		printf "%s%s %s\n",INDENT, "include_tasks:", $2
		if ( NF > 2){
			printf "%svars:\n",INDENT
			for(i=3; i <= NF; i+=2) {
				gsub("=", ": ", $i); printf "%s%s%s\"{{ %s }}\"\n",INDENT,INDENT,$i,$(i+1)
			}
		}
		m=NULL
	}' $1
