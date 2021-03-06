if [[ "$@" =~ "--debug" ]]; then
	set -ex
else
	set -e
fi

invalidband=1
cfileband=0
statusband=0
rfileband=0
dbm2band=0
dbmxband=0
mxnamesband=0
psfilterdb=0
dbmarkerband=0
sigmacfileband=0
csfileband=0
dbsgband=0
dbtaxatorband=0
dbrawtaxatorband=0
taxatortaxband=0
priorband=0
PSFDB=""
TOCLEAN=""
SIGMACFILE=""
TMPNAME="TMP_FOLDER"

INITIALPATH=$(pwd)

for i in "$@"
do
	case $i in
	"--cfile")
		cfileband=1
		invalidband=0
	;;
	"--rfile")
		rfileband=1
		invalidband=0
	;;
	"--PSfilterdb")
		psfilterdb=1
		invalidband=0
	;;
	"--dbM2")
		dbm2band=1
		invalidband=0
	;;
	"--dbmarker")
		dbmarkerband=1
		invalidband=0
	;;
	"--dbMX")
		dbmxband=1
		invalidband=0
	;;
	"--MXnames")
		mxnamesband=1
		invalidband=0
	;;
	"--sigmacfile")
		sigmacfileband=1
		invalidband=0
	;;
	"--dbSG")
		dbsgband=1
		invalidband=0
	;;
	"--dbTX")
		dbtaxatorband=1
		invalidband=0
	;;
	"--dbTXraw")
		dbrawtaxatorband=1
		invalidband=0
	;;
	"--TXtax")
		taxatortaxband=1
		invalidband=0
	;;
	"--csfile")
		csfileband=1
		invalidband=0
	;;
	"--tprior")
		priorband=1
		invalidband=0
	;;
	"--help")
	invalidband=0
		echo "#########################################################################################"
		printf "\nUsage: bash executionMethods --cfile [config file] --rfile [readsfile] -[DB options] [databases]"
		printf "\nOptions aviable:"
		echo "--cfile configuration file check README for more information"
		echo "--rfile reads file, if you have paired end reads, use: --rfile readfile1.fa,readfile2.fa"
		
		echo "--PSfilterdb pathoscope filter databases prefix"
		echo "--dbmarker is the pkl file used by metaphlan, if you don't use metaphlan, don't use this flag (full path)"
		echo "--sigmacfile is the configuration file used by sigma, if in your cfile, SIGMA is in the METHODS flag, you must provide the sigmacfile"
		echo "--tprior thetaPrior option of pathoscope"
		
		printf "\nDB options:"
		echo "--dbPS pathoscope database folder and prefix: e.g /home/user/dbpathoscope_bt2/targetdb (bowtie2 index)"
		echo "--dbM2 metaphlan database folder and prefix: e.g /home/user/dbmarkers_bt2/targetdb (bowtie2 index)"
		echo "--dbMX metamix database folder and prefix: e.g /home/user/dbmetamix_nhi/targetdb (blast index)"
		echo "--MXnames metamix names translation, is a file with format 'ti name'"
		echo "--dbSG sigma database folder (master directory)"
		echo "--dbCS constrains database folder"
		echo "note: you must provide sigma database folder in the sigma config file"
		printf "\n#########################################################################################"
		exit
	;;
	*)
		
		if [ $((cfileband)) -eq 1 ];then

			if ! [ -f $i ];then
				echo "$i file no exist"
				exit
			fi

			for parameter in $(awk '$0 !~ /^#/ {print}' $i |awk '{if($0!="")print}')
			do
				Pname=$(echo "$parameter" |awk -F"=" '{print $1}')
				case $Pname in
					"METHOD")
						METHOD=$(echo "$parameter" | awk -F"=" '{print $2}' | sed "s/,/ /g")
					;;
					"CORES")
						CORES=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"THREADS")
						THREADS=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"PYTHONBIN")
						PYTHONBIN=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"PATHOSCOPEHOME")
						PATHOSCOPEHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"DBPS")
						DBPS=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"DBPSDIR")
						DBPSDIR=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"SIGMAHOME")
						SIGMAHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"BLASTHOME")
						BLASTHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"METAPHLAN2HOME")
						METAPHLAN2HOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"CONSTRAINSHOME")
						CONSTRAINSHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"SAMTOOLSHOME")
						SAMTOOLSHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"BOWTIE2HOME")
						BOWTIE2HOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"KRAKENHOME")
						KRAKENHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"DBKR")
						DBKR=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"TAXATORHOME")
						TAXATORHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"TAXATORTK_TAXONOMY_NCBI")
						TAXATORTK_TAXONOMY_NCBI=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"CENTRIFUGEHOME")
						CENTRIFUGEHOME=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"CENTRIFUGEDB")
						DBCF=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;
					"COORDFOLDER")
						COORDFOLDER=$(echo "$parameter" | awk -F"=" '{print $2}')
					;;				
				esac
			done
			if [ "$COORDFOLDER" == "" ];then
				COORDFOLDER=$HOME
			else
				cd $COORDFOLDER
				COORDFOLDER=$(pwd)
				cd $OLDPWD
			fi
			statusband=$((statusband+1))
			cfileband=0
		fi
		
		if [ $((rfileband)) -eq 1 ]; then
			#first, we check if exist the pair end call.
			IRFILE=$i
			rfileband=0
			READS=$(echo "$i" |awk 'BEGIN{FS=","}{if($2 == ""){print "single"}else{print "paired"}}')
		fi
		
		if [ $((dbm2band)) -eq 1 ]; then
			if [ ! -f $METAPHLAN2HOME/metaphlan2.py ]; then
				echo "metaphlan2.py no exist in $METAPHLAN2HOME"
				exit
			fi	
			
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBM2=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				M2IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $M2IXDIR
				dbpath=`pwd`
				DBM2=`echo "$dbpath/$DBM2"`
				dbm2band=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmxband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBMX=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				MXIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $MXIXDIR
				dbpath=`pwd`
				DBMX=`echo "$dbpath/$DBMX"`
				dbmxband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((mxnamesband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				MXNAMES=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				MXNIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $MXNIXDIR
				dbpath=`pwd`
				MXNAMES=`echo "$dbpath/$MXNAMES"`
				mxnamesband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((psfilterdb)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				PSFDB=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				PSFIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $PSFIXDIR
				dbpath=`pwd`
				PSFDB=`echo "$dbpath/$PSFDB"`
				psfilterdb=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmarkerband)) -eq 1 ]; then
			if [ -f $i ]; then
				DBMARKER=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				M2MIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $M2MIXDIR
				dbpath=`pwd`
				DBMARKER=`echo "$dbpath/$DBMARKER"`
				dbmarkerband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi
		
		if [ $((sigmacfileband)) -eq 1 ]; then
			if [ -f $i ]; then
				SIGMACFILE=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				SGIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $SGIXDIR
				dbpath=`pwd`
				SIGMACFILE=`echo "$dbpath/$SIGMACFILE"`
				sigmacfileband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi

		fi

		if [ $((dbsgband)) -eq 1 ]; then
			if [ -d $i ]; then
				cd $i
				DBSG=`pwd`
				dbsgband=0
				cd $INITIALPATH

			else
				echo "$i master directory no exist"
				exit
			fi

		fi

		if [ $((csfileband)) -eq 1 ]; then
			if [ -f $i ]; then
				CSFILE=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				CSIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $CSIXDIR
				dbpath=`pwd`
				CSFILE=`echo "$dbpath/$CSFILE"`
				csfileband=1
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbtaxatorband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBTX=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				TXIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $TXIXDIR
				dbpath=`pwd`
				DBTX=`echo "$dbpath/$DBTX"`
				dbtaxatorband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi
		
		if [ $((taxatortaxband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				TXTAX=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				TXTAXIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $TXTAXIXDIR
				dbpath=`pwd`
				TXTAX=`echo "$dbpath/$TXTAX"`
				taxatortaxband=0
				cd $INITIALPATH

			else
				echo "$i taxator tax file no exist"
				exit
			fi
		fi

		if [ $((dbrawtaxatorband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				DBTXR=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				TXRIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $TXRIXDIR
				dbpath=`pwd`
				DBTXR=`echo "$dbpath/$DBTXR"`
				dbrawtaxatorband=0
				cd $INITIALPATH

			else
				echo "$i taxator tax file no exist"
				exit
			fi
		fi

		if [ $((priorband)) -eq 1 ]; then
				PRIOR=$i
				priorband=0

		fi

		if [ $((invalidband)) -eq 1 ]; then
			echo "some of your parameters are invalid"
			exit
		else
			invalid=1
		fi

	;;
	esac
done

#################################################
declare pids
pindex=0
maxexe=$CORES
#################################################
lastpid=0

function coresControlFunction {

	request=$1
	if mkdir $COORDFOLDER/lockfolder_donttouch > /dev/null 2>&1; then

		echo "coresControlFunction called by $2"

		if [ -f "$COORDFOLDER"/corescontrol ]; then
			i=$(tail -n1 $COORDFOLDER/corescontrol)
		else
			touch $COORDFOLDER/corescontrol
			i=0
		fi

		if [ -f $COORDFOLDER/proccesscontrol ];then
			firstproc=$(head -n1 $COORDFOLDER/proccesscontrol |awk '{print $1}')
			firstcore=$(head -n1 $COORDFOLDER/proccesscontrol |awk '{print $2}')
		else
			firstproc="foo_proccess_foo"
			touch $COORDFOLDER/proccesscontrol
		fi

		if [ $((i)) -ge $((maxexe)) ]; then

			while [[ ( -d /proc/"$firstproc" ) && ( -z "grep zombie /proc/$firstproc/status" ) ]]; do
				#echo "waiting for proccess $firstproc"
 		          sleep 61
 		      done
 		      
 		      sed "1d" $COORDFOLDER/proccesscontrol >toreplace
 		      rm $COORDFOLDER/proccesscontrol
 		      mv toreplace $COORDFOLDER/proccesscontrol

 		      sed "1d" $COORDFOLDER/corescontrol >toreplace
 		      rm $COORDFOLDER/corescontrol
 		      mv toreplace $COORDFOLDER/corescontrol

			i=$(echo "$i $firstcore" |awk '{print $1-$2}')
			echo "$i" >> "$COORDFOLDER"/corescontrol

		else
			echo "$request $i" |awk -v maxexe=$maxexe '{if($1+$2>=maxexe){print maxexe}else{print $1+$2}}' >>$COORDFOLDER/corescontrol
		fi

	else
		sleep 60
		coresControlFunction $request
	fi
}

function coresunlockFunction {

	rm -rf $COORDFOLDER/lockfolder_donttouch
}

function fastalockFunction {
	if mkdir fastalock > /dev/null 2>&1; then
		echo "fastalock created by $1"
	else
		sleep 60
		fastalockFunction
	fi
}

function fastaunlockFunction {

	rm -rf fastalock
	echo "fastalock removed"
}

function readstoFastqFunction {
		if [ "$READS" == "paired" ]; then
			PAIREND1=$(echo "$IRFILE" |awk -F"," '{print $1}')
			NAMEP=$(echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev)
			DIRP=$(echo "$PAIREND1" |rev |cut -d "/" -f 2- |rev)
			cd $DIRP
			PAIREND1=$(pwd |awk -v name=$NAMEP '{print $1"/"name}')
			cd $OLDPWD
			
			PAIREND2=$(echo "$IRFILE" |awk -F"," '{print $2}')
			NAMEP=$(echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev)
			DIRP=$(echo "$PAIREND2" |rev |cut -d "/" -f 2- |rev)
			cd $DIRP
			PAIREND2=$(pwd |awk -v name=$NAMEP '{print $1"/"name}')
			cd $OLDPWD

			arefastq=$(echo $PAIREND1 |awk -F"." '{print $NF}' )
			if [ "$arefastq" == "fastq" ] || [ "$arefastq" == "fq" ];then
				echo "files are in fastq, nice :D"
				RFILE=$IRFILE
				NAMEPAIREND1=$(echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev)
				NAMEPAIREND2=$(echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev)

				return 0
			fi

			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					NAMEPAIREND1=$(echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev)
					NAMEPAIREND2=$(echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev)

					fastalockFunction $1
					fasta_to_fastqFunction 

					if [ ! -f $TMPNAME/$NAMEPAIREND1.fastq ];then
						perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
						perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
					fi

					rm -f fasta_to_fastq.pl
					fastaunlockFunction

					RFILE=$(echo "$NAMEPAIREND1.fastq,$NAMEPAIREND2.fastq")
				else
					echo "$PAIREND2 doesn't exist"
					exit
				fi
			else
				echo "$PAIREND1 doesn't exist"
				exit
			fi
		else
			fastalockFunction $1
			if [ -f fasta_to_fastq.pl ]; then
				if [ ! -f $TMPNAME/$SINGLE.fastq ];then
					perl fasta_to_fastq.pl $IRFILE > $TMPNAME/$SINGLE.fastq
					RFILE=$SINGLE.fastq
				fi
			else
				fasta_to_fastqFunction
				if [ ! -f $TMPNAME/$SINGLE.fastq ];then
					perl fasta_to_fastq.pl $IRFILE > $TMPNAME/$SINGLE.fastq
					RFILE=$SINGLE.fastq
				fi
			fi
			fastaunlockFunction
		fi
}

function pathoscopeFunction {

		echo "Wake up pathoscope2"
		FILE=$IRFILE
		readstoFastqFunction "pathoscope2"
		cd $TMPNAME
		coresControlFunction 1 "Pathoscope2 F1"


		if [ "$PSFDB" == "" ];then
			${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py MAP -1 $PAIREND1 -2 $PAIREND2 -indexDir $DBPSDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$NAMEPAIREND1.$NAMEPAIREND2.sam  -expTag MAPPED_$NAMEPAIREND1.$NAMEPAIREND2 -numThreads $THREADS -btHome $BOWTIE2HOME
		#	{ time -p ${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $DBPSDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$NAMEPAIREND1.$NAMEPAIREND2.sam  -expTag MAPPED_$NAMEPAIREND1.$NAMEPAIREND2 -numThreads $THREADS 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf1_$NAMEPAIREND1.$NAMEPAIREND2 &
			lastpid=$!
			SAMFILE=pathoscope_$NAMEPAIREND1.$NAMEPAIREND2.sam
		else
			{ time ${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $DBPSDIR -targetIndexPrefixes $DBPS -filterIndexPrefixes $PSFDB -outDir . -outAlign pathoscope_$NAMEPAIREND1.NAMEPAIREND2.sam  -expTag MAPPED_$NAMEPAIREND1.NAMEPAIREND2 -numThreads $THREADS 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf1_$NAMEPAIREND1.$NAMEPAIREND2 &
			lastpid=$!
			SAMFILE=pathoscope_$NAMEPAIREND1.$NAMEPAIREND2.sam
		fi
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 pathoscopeF1" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction

		cd ..
		
		TOCLEAN=$RFILE
		IRFILE=$FILE
}

function metaphlanFunction {

		FILE=$IRFILE

		echo "Wake up metaphlan2"
		readstoFastqFunction "metaphlan2"
		cd $TMPNAME

		coresControlFunction 1 "Metaphlan2 F1"
		if [ -f "bowtieout$RFILE.bz2" ];then
			rm -f bowtieout$RFILE.bz2
		fi
		
		${PYTHONBIN} ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$NAMEPAIREND1.$NAMEPAIREND2.bz2 --nproc $CORES > ../metaphlan_$NAMEPAIREND1.$NAMEPAIREND2.dat
	
	#	{ time -p ${PYTHONBIN} ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$NAMEPAIREND1.$NAMEPAIREND2.bz2 --nproc $CORES > ../metaphlan_$NAMEPAIREND1.$NAMEPAIREND2.dat ; } 2>&1 |grep "real" |awk '{print $2}' > TimeM2_$NAMEPAIREND1.$NAMEPAIREND2 &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 metaphlanF1" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction
		
		cd ..

		TOCLEAN=$RFILE
		IRFILE=$FILE
}

function metamixFunction {

		echo "Wake up metamix"
		if [ "$READS" == "paired" ]; then
			PAIREND1=$(echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}')
			PAIREND2=$(echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}')
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					
					P1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					P2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
					
					if mkdir $TMPNAME/metamix_$P1.$P2 1>/dev/null; then #we make new folder because is easier to clean after execution
						echo "folder metamix_$P1.$P2 created"
					else
						echo "Metamix: cleaning previous run"
						rm -r $TMPNAME/metamix_$P1.$P2
						mkdir $TMPNAME/metamix_$P1.$P2
					fi

					cd $TMPNAME
					cd metamix_$P1.$P2
					
					coresControlFunction 1 "Metamix F1_1"
					${BLASTHOME}/bin/blastn -query $PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$P1.tab
				#	{ time -p ${BLASTHOME}/bin/blastn -query $PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$P1.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$P1 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 metamixF1_1" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction


					coresControlFunction 1 "Metamix F1_2"
					${BLASTHOME}/bin/blastn -query $PAIREND2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$P2.tab
				#	{ time -p ${BLASTHOME}/bin/blastn -query $PAIREND2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$P2.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$P2 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 metamixF1_2" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction

			        cd ..
					cd ..
									
				else
					echo "$PAIREND2 no exist"
					exit
				fi
			else
				echo "$PAIREND1 no exist"
				exit
			fi
		else
			SINGLE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`

			if mkdir $TMPNAME/metamix_$SINGLE 1>/dev/null; then #we make new folder because is easier to clean after execution
				echo "folder metamix_$SINGLE created"
			else
				echo "Metamix: cleaning previous run"
				rm -r $TMPNAME/metamix_$SINGLE
				mkdir $TMPNAME/metamix_$SINGLE
			fi

			cd $TMPNAME
			cd metamix_$SINGLE

			coresControlFunction 1 "Metamix F1"

			${BLASTHOME}/bin/blastn -query $IRFILE -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$SINGLE.tab
		#	{ time -p ${BLASTHOME}/bin/blastn -query $IRFILE -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$SINGLE.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$SINGLE &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES metamixF1" >> $COORDFOLDER/proccesscontrol
			coresunlockFunction
			cd ..
			cd ..
		fi
}

function sigmaFunction { 

	echo "Wake up sigma"
	cd $TMPNAME

	coresControlFunction 1 "Sigma F1"

	if [ "$RTYPE" == "PAIRED" ];then
		SGTOCLEAN=sigma_$RFILE
		if mkdir $SGTOCLEAN > /dev/null 2>&1;then
			cd $SGTOCLEAN
		else
			echo "sigma: cleaning previous run"
			rm -rf $SGTOCLEAN
			mkdir $SGTOCLEAN
			cd $SGTOCLEAN
		fi
	else
		SGTOCLEAN=sigma_$RFILE
		if mkdir $SGTOCLEAN > /dev/null 2>&1;then
			cd $SGTOCLEAN
		else
			echo "sigma: cleaning previous run"
			rm -rf $SGTOCLEAN
			mkdir $SGTOCLEAN
			cd $SGTOCLEAN
		fi
	fi
	mv ../$SIGMACFILE .
	# { time -p ${SIGMAHOME}/bin/sigma-align-reads -c $SIGMACFILE -w . 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimeSGf1_$NAMEPAIREND1.$NAMEPAIREND2 &
	${SIGMAHOME}/bin/sigma-align-reads -c $SIGMACFILE -w .

	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 sigmaF1" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction
	cd ..
	cd ..
}

function krakenFunction {

	echo "Wake up kraken"
	cd $TMPNAME
	if [ "$READS" == "paired" ]; then
		PAIREND1=$(echo "$IRFILE" |awk -F"," '{print "../"$1}')
		PAIREND2=$(echo "$IRFILE" |awk -F"," '{print "../"$2}')
		#next, check the files (tolerance to missing files)
		if [ -f "$PAIREND1" ];then
			if [ -f "$PAIREND2" ];then
					
				P1=$(echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev)
				P2=$(echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev)
								
				coresControlFunction 1 "Kraken F1"
				${KRAKENHOME}/kraken --db $DBKR --paired $PAIREND1 $PAIREND2 --threads $THREADS --preload > kraken_$P1.$P2.kraken
			#	{ time -p ${KRAKENHOME}/kraken --db $DBKR --paired $PAIREND1 $PAIREND2 --threads $THREADS --preload > kraken_$P1.$P2.kraken ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf1_$P1.$P2 &
				lastpid=$!
				pids[${pindex}]=$lastpid
				pindex=$((pindex+1))
				echo "$lastpid 1 krakenF1" >> $COORDFOLDER/proccesscontrol
				coresunlockFunction
		
			else
				echo "$PAIREND2 no exist"
				exit
			fi
		else
			echo "$PAIREND1 no exist"
			exit
		fi
	else
		coresControlFunction 1 "Kraken F1"
		SINGLE=$(echo "$IRFILE" |rev |cut -d "/" -f 1 |rev)
		${KRAKENHOME}/kraken --db $DBKR ../$IRFILE --threads $THREADS --preload > kraken_$SINGLE.kraken
	#	{ time -p ${KRAKENHOME}/kraken --db $DBKR ../$IRFILE --threads $THREADS --preload > kraken_$SINGLE.kraken ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf1_$SINGLE &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 krakenF1" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction
	fi

	cd ..

}

function taxatorFunction {

		echo "Wake up taxator-tk"
		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					
					P1=$(echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev)
					P2=$(echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev)
					
					if mkdir $TMPNAME/taxator_$P1.$P2 1>/dev/null; then #we make new folder because is easier to clean after execution
						echo "folder taxator_$P1.$P2 created"
					else
						echo "Taxator: cleaning previous run"
						rm -r $TMPNAME/taxator_$P1.$P2
						mkdir $TMPNAME/taxator_$P1.$P2
					fi

					cd $TMPNAME
					cd taxator_$P1.$P2
					
					coresControlFunction 1 "Taxator F1_1"
					${BLASTHOME}/bin/blastn -query $PAIREND1 -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$P1.tab
				#	{ time -p ${BLASTHOME}/bin/blastn -query $PAIREND1 -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$P1.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeTXf1_$P1 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 taxatorF1_1" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction


					coresControlFunction 1 "Taxator F1_2"
					${BLASTHOME}/bin/blastn -query $PAIREND2 -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$P2.tab
				#	{ time -p ${BLASTHOME}/bin/blastn -query $PAIREND2 -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$P2.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeTXf1_$P2 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 taxatorF1_2" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction

			        cd ..
					cd ..
				else
					echo "$PAIREND2 no exist"
					exit
				fi
			else
				echo "$PAIREND1 no exist"
				exit
			fi
		else
			SINGLE=$(echo "$IRFILE" |rev |cut -d "/" -f 1 |rev)

			if mkdir $TMPNAME/taxator_$SINGLE 1>/dev/null; then #we make new folder because is easier to clean after execution
				echo "folder taxator_$SINGLE created"
			else
				echo "Taxator: cleaning previous run"
				rm -r $TMPNAME/taxator_$SINGLE
				mkdir $TMPNAME/taxator_$SINGLE
			fi

			cd $TMPNAME
			cd taxator_$SINGLE

			coresControlFunction $CORES "Taxator F1"
			${BLASTHOME}/bin/blastn -query $IRFILE -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$SINGLE.tab
		#	{ time -p ${BLASTHOME}/bin/blastn -query $IRFILE -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$SINGLE.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$SINGLE &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES taxatorF1" >> $COORDFOLDER/proccesscontrol
			coresunlockFunction
			cd ..
			cd ..
		fi

}

function centrifugeFunction {

		echo "Wake up centrifuge"
		readstoFastqFunction "Centrifuge"

		if [ "$READS" == "paired" ]; then
					
			P1=$(echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev)
			P2=$(echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev)
			
			if mkdir $TMPNAME/centrifuge_$P1.$P2 1>/dev/null; then #we make new folder because is easier to clean after execution
				echo "folder centrifuge_$P1.$P2 created"
			else
				echo "Centrifuge: cleaning previous run"
				rm -r $TMPNAME/centrifuge_$P1.$P2
				mkdir $TMPNAME/centrifuge_$P1.$P2
			fi

			cd $TMPNAME
			cd centrifuge_$P1.$P2
			
			coresControlFunction $CORES "Centrifuge F1"
			${CENTRIFUGEHOME}/bin/centrifuge -p $CORES -x $DBCF -1 $PAIREND1 -2 $PAIREND2 > centrifuge_$P1.$P2.tsv
		#	{ time -p ${CENTRIFUGEHOME}/bin/centrifuge -p $CORES -x $DBCF -1 $PAIREND1 -2 $PAIREND2 > centrifuge_$P1.$P2.tsv ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeCF_$P1.$P2 &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES centrifugeF1" >> $COORDFOLDER/proccesscontrol

			coresunlockFunction

			cd ..
			cd ..
					
		else
			SINGLE=$(echo "$RFILE" |rev |cut -d "/" -f 1 |rev)

			if mkdir $TMPNAME/centrifuge_$SINGLE 1>/dev/null; then #we make new folder because is easier to clean after execution
				echo "folder centrifuge_$SINGLE created"
			else
				echo "Centrifuge: cleaning previous run"
				rm -r $TMPNAME/centrifuge_$SINGLE
				mkdir $TMPNAME/centrifuge_$SINGLE
			fi

			cd $TMPNAME
			cd centrifuge_$SINGLE

			coresControlFunction $CORES "Centrifuge F1"
			${CENTRIFUGEHOME}/bin/centrifuge -p $CORES -x $DBCF ../../$SINGLE > centrifuge_$SINGLE.tsv
		#	{ time -p ${CENTRIFUGEHOME}/bin/centrifuge -p $CORES -x $DBCF ../../$SINGLE > centrifuge_$SINGLE.tsv ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeCF_$SINGLE &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES CentrifugeF1" >> $COORDFOLDER/proccesscontrol
			coresunlockFunction
			cd ..
			cd ..
		fi

}

function pathoscopeFunction2 {
	echo "executing pathoscope ID module"
	cd $TMPNAME

	coresControlFunction 1 "Pathoscope2 F2"
	if [ "$PRIOR" == "" ];then
		${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE
	#	{ time -p ${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf2_$NAMEPAIREND1.$NAMEPAIREND2 &

	else
		${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $PRIOR
	#	{ time -p ${PYTHONBIN} ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $PRIOR 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf2_$NAMEPAIREND1.$NAMEPAIREND2 &
	fi
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 pathoscopeF2" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction
	cd ..

}

function metamixFunction2 {

	cd $TMPNAME

	coresControlFunction 12 "Metamix F2" #parallel tempering requires 12 cores

		if [ "$READS" == "paired" ]; then
			cat TimeMXf1_$P1 TimeMXf1_$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeMXf1_$P1.$P2
			rm -f TimeMXf1_$P1 TimeMXf1_$P2
			cd metamix_$P1.$P2
			BACKUPNAME=$(echo "metamix_$P1.$P2")
			metamixCodeFunction
			echo "call to metamix R function"
			cat blastOut$P1.tab blastOut$P2.tab > blastOut$P1.$P2.tab
			rm blastOut$P1.tab blastOut$P2.tab
			executionpath=$(pwd)

			executeMetamix blastOut$P1.$P2.tab $executionpath
		#	{ time -p executeMetamix blastOut$P1.$P2.tab $executionpath 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf2_$P1.$P2 &

			cd ..

		else
			cd metamix_$SINGLE
			metamixCodeFunction
			echo "execute metamix R function"
			executionpath=$(pwd)
		
			executeMetamix blastOut$SINGLE.tab $executionpath
		#	{ time -p executeMetamix blastOut$SINGLE.tab $executionpath 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf2_$SINGLE &

			cd ..
		fi
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 metamixF2" >> $COORDFOLDER/proccesscontrol

		coresunlockFunction
		cd ..

}

function sigmaFunction2 {
	cd $TMPNAME 
	cd $SGTOCLEAN

	#Sigma don't allow several intances, so we set until 2 parallel instances
	twoInstances=$(echo $CORES |awk '{print int($1/2)}')
	coresControlFunction $twoInstances "Sigma F2"

	echo "executing sigma wrapper module"	
    # { time -p ${SIGMAHOME}/bin/sigma -c $SIGMACFILE -t $THREADS -w . 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimeSGf2_$RFILE &
	${SIGMAHOME}/bin/sigma -c $SIGMACFILE -t $THREADS -w .

	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid $twoInstances SigmaF2" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction

	cd ..
	cd ..

}

function constrainsFunction {

	echo "Wake up constrains"

	readstoFastqFunction "constrains"

	cd $TMPNAME
	coresControlFunction $CORES "Constrains F2"
	if [ -f "../metaphlan_$NAMEPAIREND1.$NAMEPAIREND2.dat" ];then
		CSERROR=0
		CSTOCLEAN=$(echo "$NAMEPAIREND1.$NAMEPAIREND2" |awk '{print "constrains_"$1}')

		if [ "$READS" == "paired" ]; then
			F1=$(echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}')
			F2=$(echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}')
			echo "sample: $RFILE
			fq1: $F1
			fq2: $F2
			metaphlan: ../metaphlan_$NAMEPAIREND1.$NAMEPAIREND2.dat" > cs_config_$NAMEPAIREND1.$NAMEPAIREND2.conf
		else
			echo "sample: $RFILE 
			fq: $RFILE
			metaphlan: ../metaphlan_$NAMEPAIREND1.$NAMEPAIREND2.dat" > cs_config_$NAMEPAIREND1.$NAMEPAIREND2.conf
			CSTOCLEAN=constrains_$NAMEPAIREND1.$NAMEPAIREND2
		fi
		#	{ time -p ${PYTHONBIN} ${CONSTRAINSHOME}/ConStrains.py -c cs_config_$NAMEPAIREND1.$NAMEPAIREND2.conf -o $CSTOCLEAN -t $THREADS -d ${CONSTRAINSHOME}/db/ref_db -g ${CONSTRAINSHOME}/db/gsize.db --bowtie2=${BOWTIE2HOME}/bin/bowtie2-build --samtools=${SAMTOOLSHOME}/bin/samtools -m ${METAPHLAN2HOME}/metaphlan2.py 1>/dev/null ; } 2>&1 |grep "real" |awk '{print $2}' > TimeCS_$NAMEPAIREND1.$NAMEPAIREND2 &
			${PYTHONBIN} ${CONSTRAINSHOME}/ConStrains.py -c cs_config_$RFILE.conf -o $CSTOCLEAN -t $THREADS -d ${CONSTRAINSHOME}/db/ref_db -g ${CONSTRAINSHOME}/db/gsize.db --bowtie2=${BOWTIE2HOME}/bin/bowtie2-build --samtools=${SAMTOOLSHOME}/bin/samtools -m ${METAPHLAN2HOME}/metaphlan2.py &
			lastpid=$!	
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES constrains" >> $COORDFOLDER/proccesscontrol
	else
			echo "Constrains: no metaphlan_$RFILE.dat file found, impossible continue"
			CSERROR=1
	fi
	coresunlockFunction

	cd ..
			
}

function krakenFunction2 {

	cd $TMPNAME
	coresControlFunction 1 "Kraken F2"

	if [ "$READS" == "paired" ]; then
		${KRAKENHOME}/kraken-translate --mpa-format --db $DBKR kraken_$P1.$P2.kraken > kraken_trans_$P1.$P2.kraken
	#	{ time -p ${KRAKENHOME}/kraken-translate --mpa-format --db $DBKR kraken_$P1.$P2.kraken > kraken_trans_$P1.$P2.kraken ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf2_$P1.$P2 &
	else
		${KRAKENHOME}/kraken-translate --mpa-format --db $DBKR kraken_$SINGLE.kraken > kraken_trans_$SINGLE.kraken
	#	{ time -p ${KRAKENHOME}/kraken-translate --mpa-format --db $DBKR kraken_$SINGLE.kraken > kraken_trans_$SINGLE.kraken  ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf2_$SINGLE &
	fi
	
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 krakenF2" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction
	
	cd ..

}

function taxatorFunction2 {

	cd $TMPNAME

	coresControlFunction $CORES "Taxator F2"

	if [ "$READS" == "paired" ]; then
		cat TimeTXf1_$P1 TimeTXf1_$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeTXf1_$P1.$P2
		rm -f TimeTXf1_$P1 TimeTXf1_$P2
		cd taxator_$P1.$P2

		cat blastOut$P1.tab blastOut$P2.tab > blastOut$P1.$P2.tab
		rm blastOut$P1.tab blastOut$P2.tab

		awk '{print $0"\t"}' blastOut$P1.$P2.tab >  blastOut$P1.$P2.tab.tmp && rm -f blastOut$P1.$P2.tab && mv blastOut$P1.$P2.tab.tmp blastOut$P1.$P2.tab
		cat $PAIREND1 $PAIREND2 > $P1.$P2

		${TAXATORHOME}/bin/taxator -g $TXTAX -q $P1.$P2 -v $P1.$P2.fai -f $DBTXR -i $DBTXR.fai -p16 < blastOut$P1.$P2.tab |${TAXATORHOME}/bin/binner -n "$P1.$P2" > taxator_$P1.$P2.tax
	#	{ time -p ${TAXATORHOME}/bin/taxator -g $TXTAX -q $P1.$P2 -v $P1.$P2.fai -f $DBTXR -i $DBTXR.fai -p16 < blastOut$P1.$P2.tab |${TAXATORHOME}/bin/binner -n "$P1.$P2" > taxator_$P1.$P2.tax ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeTXf2_$P1.$P2 &

		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid $CORES taxatorF2" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction

		cd ..
	else
		cd taxator_$SINGLE
	
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid $CORES taxatorF2" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction

		cd ..
	fi
	

	cd ..

}

function lastStepFunction {

	rm -f $TMPNAME/fasta_to_fastq.pl

	if [ "$READS" == "paired" ]; then
		rm -f $TMPNAME/$NAMEPAIREND1.fastq $TMPNAME/$NAMEPAIREND2.fastq
	else
		rm -f $TMPNAME/$TOCLEAN.fastq
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then
	#	cp $TMPNAME/TimePSf1_$NAMEPAIREND1.$NAMEPAIREND2 . && rm -f $TMPNAME/TimePSf1_$NAMEPAIREND1.$NAMEPAIREND2
	#	cp $TMPNAME/TimePSf2_$NAMEPAIREND1.$NAMEPAIREND2 . && rm -f $TMPNAME/TimePSf2_$NAMEPAIREND1.$NAMEPAIREND2

		rm -f updated_pathoscope_$TOCLEAN.sam
		rm -f $TMPNAME/$SAMFILE
		#newpatname=$(echo "pathoscope_$RFILE.sam-sam-report.tsv")
		#mv pathoscope_$RFILE.sam-sam-report.tsv $newpatname

	fi
	
	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
	#	newmetname=$(echo "TimeM2_$NAMEPAIREND1.$NAMEPAIREND2")
	#	cp $TMPNAME/TimeM2_$RFILE $newmetname && rm -f $TMPNAME/TimeM2_$RFILE
		
		rm -f $TMPNAME/bowtieout$TOCLEAN.bz2
		newmetname=$(echo "metaphlan_$RFILE.dat" |awk -F "," '{print $1"."$2}')
		cp metaphlan_$RFILE.dat $newmetname && rm -f metaphlan_$RFILE.dat
	fi
	
	if [[ "$METHOD" =~ "METAMIX" ]]; then
		if [ "$READS" == "paired" ]; then
	#		cp $TMPNAME/TimeMXf1_$P1.$P2 . && rm -f $TMPNAME/TimeMXf1_$P1.$P2
	#		cp $TMPNAME/TimeMXf2_$P1.$P2 . && rm -f $TMPNAME/TimeMXf2_$P1.$P2
			rm -rf $TMPNAME/metamix_$P1.$P2
		else
			mv $TMPNAME/TimeMXf1_$SINGLE .
			mv $TMPNAME/TimeMXf2_$SINGLE .
			rm -rf $TMPNAME/metamix_$SINGLE
		fi
	fi
	
	if [[ "$METHOD" =~ "SIGMA" ]]; then
	#	newsigname=$(echo "TimeSGf1_$RFILE" |awk -F "," '{print $1"."$2}')
	#	cp $TMPNAME/$SGTOCLEAN/TimeSGf1_$RFILE $newsigname
	#	newsigname=$(echo "TimeSGf2_$RFILE" |awk -F "," '{print $1"."$2}')
	#	cp $TMPNAME/$SGTOCLEAN/TimeSGf2_$RFILE $newsigname

		cp $TMPNAME/$SGTOCLEAN/*.gvector.txt $SGTOCLEAN.gvector.txt
		rm -rf $TMPNAME/$SGTOCLEAN
		newsigname=$(echo "$SGTOCLEAN.gvector.txt" |awk -F "," '{print $1"."$2}')
		mv $SGTOCLEAN.gvector.txt $newsigname
	fi

	if [[ "$METHOD" =~ "CONSTRAINS" ]] && [ "$CSERROR" -eq 0 ]; then
	#	newsigname=$(echo "TimeCS_$RFILE" |awk -F "," '{print $1"."$2}')
	#	cp $TMPNAME/TimeCS_$RFILE $newsigname && rm -f $TMPNAME/TimeCS_$RFILE
		cp $TMPNAME/$CSTOCLEAN/results/Overall_rel_ab.profiles $CSTOCLEAN.profiles
		rm -rf $TMPNAME/$CSTOCLEAN
		rm -rf $TMPNAME/cs_config_$RFILE.conf

	fi

	if [[ "$METHOD" =~ "KRAKEN" ]]; then
		if [ "$READS" == "paired" ]; then
		#	cp $TMPNAME/TimeKRf1_$P1.$P2 .
		#	cp $TMPNAME/TimeKRf2_$P1.$P2 .
		#	rm -f $TMPNAME/TimeKRf1_$P1.$P2 $TMPNAME/TimeKRf2_$P1.$P2


			mv $TMPNAME/kraken_trans_$P1.$P2.kraken .
			awk '{print $2}' kraken_trans_$P1.$P2.kraken |sort -T . |uniq -c > $P1.$P2.kraken.tmp
			rm -f kraken_trans_$P1.$P2.kraken
			mv $P1.$P2.kraken.tmp kraken_$P1.$P2.kraken
		else
		#	mv $TMPNAME/TimeKRf1_$SINGLE .
		#	mv $TMPNAME/TimeKRf2_$SINGLE .

			mv $TMPNAME/kraken_trans_$SINGLE.kraken .
			awk '{print $2}' kraken_trans_$SINGLE.kraken |sort -T . |uniq -c > $SINGLE.kraken.tmp
			rm kraken_trans_$SINGLE.kraken
			mv $SINGLE.kraken.tmp kraken_$SINGLE.kraken
		fi
	fi

	if [[ "$METHOD" =~ "TAXATOR" ]]; then
		if [ "$READS" == "paired" ]; then
		#	cp $TMPNAME/TimeTXf1_$P1.$P2 . && rm -f $TMPNAME/TimeTXf1_$P1.$P2
		#	cp $TMPNAME/TimeTXf2_$P1.$P2 . && rm -f $TMPNAME/TimeTXf2_$P1.$P2
			cp $TMPNAME/taxator_$P1.$P2/taxator_$P1.$P2.tax .
			rm -rf $TMPNAME/taxator_$P1.$P2

		else
		#	cp $TMPNAME/TimeTXf1_$SINGLE .
		#	cp $TMPNAME/TimeTXf2_$SINGLE .
			cp $TMPNAME/taxator_$SINGLE/taxator_$SINGLE.tax .
			rm -rf $TMPNAME/taxator_$SINGLE
		fi
	fi

	if [[ "$METHOD" =~ "CENTRIFUGE" ]]; then
		if [ "$READS" == "paired" ]; then
		#	cp $TMPNAME/TimeCF_$P1.$P2 . && rm -f $TMPNAME/TimeCF_$P1.$P2
			cp $TMPNAME/centrifuge_$P1.$P2/centrifuge_$P1.$P2.tsv .
			rm -rf $TMPNAME/centrifuge_$P1.$P2
		else
		#	cp $TMPNAME/TimeCF_$SINGLE .
			cp $TMPNAME/centrifuge_$SINGLE/centrifuge_$SINGLE.tsv .
			rm -rf $TMPNAME/taxator_$SINGLE
		fi
	fi

	echo "Done :D"

}

function criticalvariablesFunction {

	pass=0
	echo "Checking critical variables:"

	if [ ! -f "$PYTHONBIN" ];then
		echo "* You must provide the python binary e.g. /usr/bin/python"
		pass=$((pass+1))
	fi

	if [ "$IRFILE" == "" ];then
		echo "* You must provide a read file"
		pass=$((pass+1))
	fi

	if [ "$CORES" == "" ] || [ "$THREADS" == "" ]
	then
		echo "* Cores or threads are null, you must specify in the config file"
		pass=$((pass+1))
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then

		if [ "$DBPS" == "" ] || [ "DBPSDIR" == "" ];then
			echo "* You must provide a database (bowtie2 index), for pathoscope in config file (DBPS and DBPSDIR)"
			pass=$((pass+1))
		fi
		if [ "$PATHOSCOPEHOME" == "" ];then
			echo "* No PATHOSCOPEHOME is specified"
			pass=$((pass+1))
		fi
		if ! [ -f $PATHOSCOPEHOME/pathoscope2.py ];then
			echo "* pathoscope2.py no exist in $PATHOSCOPEHOME"
			pass=$((pass+1))
		fi
		if [ "$BOWTIE2HOME" == "" ];then
			echo "* You must provide a bowtie2 home in config file (BOWTIE2HOME flag in config file)"
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		if [ "$DBM2" == "" ] || [ "$DBMARKER" == "" ];then
			echo "* METAPHLAN is specify in the config file, but you must provide a database (bowtie2 index), and pkl file in the command line (--dbM2 and --dbmarker)"
			pass=$((pass+1))
		fi
		if [ "$METAPHLAN2HOME" == "" ];then
			echo "* No METAPHLAN2HOME\n"
			pass=$((pass+1))
		fi	
	
		if ! [ -f $METAPHLAN2HOME/metaphlan2.py ]; then
			echo "* metaphlan2.py no exist in $METAPHLAN2HOME"
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "METAMIX" ]]; then

		if [ "$DBMX" == "" ];then
			echo "* You must provide a database (blast index), for metamix (--dbMX)"
			pass=$((pass+1))
		fi

		if [ "$MXNAMES" == "" ];then
			echo "* You must provide the names of your blast database (--MXnames), this file have ti - name format (183214 Foo)"
			pass=$((pass+1))
		fi

		if [ "$BLASTHOME" == "" ];then
			echo "* You must provide BLASTHOME in config file"
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "SIGMA" ]]; then

		if [ "$SIGMAHOME" == "" ];then
			echo "* No SIGMAHOME is specified"
			pass=$((pass+1))
		fi

		if ! [  -f $SIGMAHOME/bin/sigma ];then
			echo "* sigma no exist in $SIGMAHOME/bin"
			pass=$((pass+1))
		fi

		
		if [ "$SIGMACFILE" == "" ];then

			if [ "$BOWTIE2HOME" == "" ];then
				echo "* You must provide a bowtie2 home in config file (BOWTIE2HOME flag), to generate sigma config file"
				pass=$((pass+1))
			fi
			
			if [ "$SAMTOOLSHOME" == "" ];then
				echo "* You must provide a samtools binary folder (home/bin) (SAMTOOLSHOME flag), to generate sigma config file"
				pass=$((pass+1))
			fi

			if [ "$DBSG" == "" ]; then
				echo "* You must provide a sigma database path, to generate sigma config file"
				pass=$((pass+1))
			fi

			if [ "$READS" == "paired" ]; then
				RTYPE="PAIRED"
			else
				RTYPE="SINGLE"
			fi

			if [ $((pass)) -eq 0 ];then
				sigmaCfileFunction
				SIGMACFILE=`echo "sigma_$RFILE""_config.cfg"`

			else
				echo "* You must fix this errors to continue"
				exit
			fi

		else

			DBSG=`grep -1 "Reference_Genome_Directory" $SIGMACFILE |cut -d "=" -f 2`
			PR1=`grep -1 "Paired_End_Reads_1" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`
			PR2=`grep -1 "Paired_End_Reads_2" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`
			SR=`grep -1 "Single_End_Reads" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`

			if [ -d $DBSG ];then
					echo "* You must provide a database folder in sigma config file"
					pass=$((pass+1))
			fi
			if [ "$SR" == "" ];then
				if [ "$PR1" == "" ] || [ "$PR2" == "" ]; then
					echo "* You must provide a read file in sigma config file"
					pass=$((pass+1))
				else
					RTYPE="PAIRED"
				fi
			else
				RTYPE="SINGLE"
			fi
		fi
	fi

	if [[ "$METHOD" =~ "KRAKEN" ]]; then
		if [ "$DBKR" == "" ];then
			echo "* You must provide a database (folder), for kraken (--dbKR)"
			pass=$((pass+1))
		fi
		if [ "$KRAKENHOME" == "" ];then
			echo "* You no KRAKENHOME is specified"
			pass=$((pass+1))
		fi
		if ! [ -f $KRAKENHOME/kraken ];then
			echo "* You kraken no exist in $KRAKENHOME"
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "TAXATOR" ]]; then
		if [ "TAXATORTK_TAXONOMY_NCBI" == "" ];then
			echo "* You must provide a TAXATORTK_TAXONOMY_NCBI path for taxator-tk in the config file (TAXATORTK_TAXONOMY_NCBI=/path/to/your/ncbi taxonomi)"
			pass=$((pass+1))
		else
			export TAXATORTK_TAXONOMY_NCBI=$TAXATORTK_TAXONOMY_NCBI
		fi

		if [ "$DBTX" == "" ];then
			echo "* You must provide a database (blast index), for taxator (--dbTX)"
			pass=$((pass+1))
		fi
		
		if [ "$DBTXR" == "" ];then
			echo "* You must provide a raw database for taxator (--dbTXraw), the same fna/fasta that was used for construct the index in blast"
			pass=$((pass+1))
		fi

		if [ "$TXTAX" == "" ];then
			echo "* You must provide a tax .file for taxator (--TXtax)"
			pass=$((pass+1))
		fi

		if [ "$TAXATORHOME" == "" ];then
			echo "* You must provide a taxator home in the config file"
			pass=$((pass+1))
		fi

		if ! [ -f $TAXATORHOME/bin/taxator ];then
			echo "* Taxator no exist in $TAXATORHOME/bin"
			pass=$((pass+1))
		fi

	fi

	if [[ "$METHOD" =~ "CENTRIFUGE" ]]; then
		if [ "$DBCF" == "" ];then
			echo "* You must provide a database (centrifuge index), for centrifuge in the config file"
			pass=$((pass+1))
		else
			ok=$(ls -1 "$DBCF"* |wc -l |awk '{print $1}')
			if [ $((ok)) -ge 1 ]; then
				TMP=$(echo "$DBCF" |rev |cut -d "/" -f 1 |rev)
				DBCFDIR=$(echo "$DBCF" |rev |cut -d "/" -f 2- |rev)
				cd $DBCFDIR
				dbpath=$(pwd)
				DBCF=$(echo "$dbpath/$TMP")
				cd $INITIALPATH
			else
				echo "$DBCF file have at least three .cf files"
				pass=$((pass+1))	
			fi
		fi
	fi

	if [ $((pass)) -eq 0 ];then
		echo "* All parameters ok"
		echo "Launch zone"
	else
		exit
	fi

}

function sigmaCfileFunction {

	if [ "$READS" == "paired" ]; then
		F1=$(echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}')
		SIZE=$(tail -n1 $F1 |wc |awk '{print $3}')
		F1=$(echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}' |rev |cut -d "/" -f 1 |rev)
		F1=$(echo "$F1.fastq")
		F2=$(echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}' |rev |cut -d "/" -f 1 |rev)
		F2=$(echo "$F2.fastq")
		
		readstoFastqFunction "sigma"
		cd $TMPNAME	
		FASTQFOLDER=$(pwd)
		cd ..
		RFILE=$(echo "$F1.$F2")
		#RFILE=`echo "$F1,$F2"`
		
		echo "[Program_Info]
Bowtie_Directory=$BOWTIE2HOME/bin
Samtools_Directory=$SAMTOOLSHOME/bin
[Data_Info]
Reference_Genome_Directory=$DBSG
Paired_End_Reads_1=$FASTQFOLDER/$F1
Paired_End_Reads_2=$FASTQFOLDER/$F2
[Bowtie_Search]
Maximum_Mismatch_Count=3
Minimum_Fragment_Length=0
Maximum_Fragment_Length=2000
Bowtie_Threads_Number=$THREADS
[Model_Probability]
Mismatch_Probability=0.05
Minimum_Relative_Abundance = 0.01
[Statistics]
Bootstrap_Iteration_Number=10
Minumum_Coverage_Length=$SIZE
Minimum_Average_Coverage_Depth=3
" > $TMPNAME/sigma_$RFILE""_config.cfg
		
	else
		SIZE=`tail -n1 $IRFILE |wc |awk '{print $3}'`
		readstoFastqFunction "sigma"
		RFILE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`
		RFILE=`echo "$RFILE.fastq"`
		cd $TMPNAME	
		FASTQFOLDER=`pwd`
		cd ..

		echo "[Program_Info]
Bowtie_Directory=$BOWTIE2HOME
Samtools_Directory=$SAMTOOLSHOME
[Data_Info]
Reference_Genome_Directory=$DBSG
Single_End_Reads=$FASTQFOLDER/$RFILE
[Bowtie_Search]
Maximum_Mismatch_Count=3
Minimum_Fragment_Length=0
Maximum_Fragment_Length=2000
Bowtie_Threads_Number=$THREADS
[Model_Probability]
Mismatch_Probability=0.05
Minimum_Relative_Abundance = 0.01
[Statistics]
Bootstrap_Iteration_Number=10
Minumum_Coverage_Length=$SIZE
Minimum_Average_Coverage_Depth=3
" > $TMPNAME/sigma_$RFILE""_config.cfg
	
	fi

}

function fasta_to_fastqFunction {
	echo '#!/usr/bin/perl
			use strict;

			my $file = $ARGV[0];
			open FILE, $file;

			my ($header, $sequence, $sequence_length, $sequence_quality);
			while(<FILE>) {
			        chomp $_;
			        if ($_ =~ /^>(.+)/) {
			                if($header ne "") {
			                        print "\@".$header."\n";
			                        print $sequence."\n";
			                        print "+"."\n";
			                        print $sequence_quality."\n";
			                }
			                $header = $1;
					$sequence = "";
					$sequence_length = "";
					$sequence_quality = "";
			        }
				else { 
					$sequence .= $_;
					$sequence_length = length($_); 
					for(my $i=0; $i<$sequence_length; $i++) {$sequence_quality .= "I"} 
				}
			}
			close FILE;
			print "\@".$header."\n";
			print $sequence."\n";
			print "+"."\n";
			print $sequence_quality."\n";' > fasta_to_fastq.pl
}

function metamixCodeFunction {
	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	blastab<-c(args[6])
	print("execute Step1")
	Step1<-generative.prob.nucl(blast.output.file=blastab,blast.default=FALSE,outDir=".")
	' > step1.R

	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	Step1<-c(args[6])
	print("execute Step2")
	Step2 <- reduce.space(step1=Step1)
	' > step2.R

	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	Step2<-c(args[6])
	print("execute Step3")
	Step3<-parallel.temper(step2=Step2)
	' > step3.R

	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	Step2<-c(args[6])
	Step3<-c(args[7])
	names<-c(args[8])
	print("execute Step4")
	step4<-bayes.model.aver(step2=Step2, step3=Step3, taxon.name.map=names)
	' > step4.R
	
}

function executeMetamix {
	#$1 blast output (fmt 6)
	#$2 $executionpath
	Rscript $2/step1.R $2/$1
	Rscript $2/step2.R $2/step1.RData
	mpirun -np 1 --quiet Rscript $2/step3.R $2/step2.RData
	Rscript $2/step4.R $2/step2.RData $2/step3.RData $MXNAMES
	mv $2/presentSpecies_assignedReads.tsv $2/../../$BACKUPNAME.assignedReads.tsv
}
#begin the code

if [ $((statusband)) -ge 1 ]; then
	cd $INITIALPATH
	#Check some parameters before do something
	if [ -d "$TMPNAME" ]; then
		echo "$TMPNAME exist, working in."
	else
		mkdir $TMPNAME
	fi

	criticalvariablesFunction

			for g in $METHOD
			do
				case $g in
					"PATHOSCOPE")
						pathoscopeFunction
				   	;;
					"METAPHLAN")
						metaphlanFunction
					;;
					"METAMIX")
						metamixFunction	
					;;
					"SIGMA")
						sigmaFunction
					;;
					"CONSTRAINS")
						#waiting for metaphlan work
					;;
					"KRAKEN")
						krakenFunction
					;;
					"TAXATOR")
						taxatorFunction
					;;
					"CENTRIFUGE")
						centrifugeFunction
					;;
					"*")
						echo "unknow method for $METHOD"
					;;
				esac
			done
		
			###SECOND PART###
			echo "waiting for mapping work"
			for pid in "${pids[@]}"
			do
			   wait $pid
			done
			unset pids
			declare pids
			pindex=0
			#to sure we are in $INITIALPATH
			cd $INITIALPATH
			for g in $METHOD
			do
				case $g in
					"PATHOSCOPE")
						pathoscopeFunction2
				   	;;
					"METAPHLAN")
						echo "Metaphlan done"
					;;
					"METAMIX")
						metamixFunction2
					;;
					"SIGMA")
						sigmaFunction2
					;;
					"CONSTRAINS")
						constrainsFunction
					;;
					"KRAKEN")
						krakenFunction2
					;;
					"TAXATOR")
						taxatorFunction2
					;;
					"CENTRIFUGE")
						echo "Centrifuge done"
					;;
				esac
			done
			echo "waiting for classification work"
			for pid in "${pids[@]}"
			do
			   wait $pid
			done
			unset pids
			
			lastStepFunction
else
	echo "Invalid or Missing Parameters, print --help to see the options"
	echo "Usage: bash executionMethods --cfile [config file] --rfile [readsfile] -[dboption] [databases]"
	exit
fi
