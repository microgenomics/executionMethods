#make sure you have installed correctly the patogen detection software 
set -e

cfileband=0
localband=0
statusband=0
rfileband=0
dbpsband=0
dbm2band=0
dbmxband=0
dbcsband=0
psfilterdb=0
dbmarkerband=0
sigmacfileband=0
PSFDB=""
TOCLEAN=""
TMPNAME="TMP_FOLDER"

for i in "$@"
do
	case $i in
	"--cfile")
		cfileband=1
	;;
	"--rfile")
		rfileband=1
	;;
	"--dbPS")
		dbpsband=1
	;;
	"--dbM2")
		dbm2band=1
	;;
	"--dbMX")
		dbmxband=1
	;;
	"--dbCS")
		dbcsband=1
	;;
	"--PSfilterdb")
		psfilterdb=1
	;;
	"--local")
		localband=1
	;;
	"--dbmarker")
		dbmarkerband=1
	;;
	"--sigmacfile")
		sigmacfileband=1
	;;
	"--help")
		echo "#########################################################################################"
		echo -e "\nUsage: bash executionMethods --cfile [config file] --rfile [readsfile] -[dboption] [databases] --local (only if you use this module alone)"
		echo -e "\nOptions aviable:"
		echo "--cfile configuration file check README for more information"
		echo "--rfile reads file, if you have paired end reads, use: --rfile readfile1.fa,readfile2.fa"
		
		echo "--local this flag is to make all works in your local folder, if you use this module separately from SEPA modules, use this flag"
		echo "--PSfilterdb pathoscope filter databases prefix"
		echo "--dbmarker is the pkl file used by metaphlan, if you don't use metaphlan, don't use this flag (full path)"
		echo "--sigmacfile is the configuration file used by sigma, if in your cfile, SIGMA is in the METHODS flag, you must provide the sigmacfile"
		echo "to apply Perdonazo method, you must especify in the config file the parameter ABSENT=yes, the script automatically calculate corresponding data"
		
		echo -e "\ndboption:"
		echo "--dbPS pathoscope database folder and prefix: e.g /home/user/dbpathoscope_bt2/targetdb (bowtie2 index)"
		echo "--dbM2 metaphlan database folder and prefix: e.g /home/user/dbmarkers_bt2/targetdb (bowtie2 index)"
		echo "--dbMX metamix database folder and prefix: e.g /home/user/dbmetamix_nhi/targetdb (blast index)"
		echo "--dbCS constrains database folder"
		echo "note: you must provide sigma database folder in the sigma config file"
		echo -e "\n#########################################################################################"
		exit
	;;
	*)
		
		if [ $((cfileband)) -eq 1 ];then

			if ! [ -f $i ];then
				echo "$i file no exist"
				exit
			fi

			for parameter in `awk '{print}' $i`
			do
				Pname=`echo "$parameter" |awk 'BEGIN{FS="="}{print $1}'`		
				case $Pname in
					"GENOMESIZEBALANCE")
						GENOMESIZEBALANCE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
						#echo "${parameters[$i]}"								
					;;
					"COMMUNITYCOMPLEX")
						COMMUNITYCOMPLEX=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"SPECIES")
						SPECIES=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"ABUNDANCE")
						ABUNDANCE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"DOMINANCE")
					DOMINANCE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"READSIZE")
						READSIZE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"ABSENT")
						ABSENT=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"METHOD")
						METHOD=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"tipermanent")
						tipermanent=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"CORES")
						CORES=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"THREADS")
						THREADS=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"PATHOSCOPEHOME")
						PATHOSCOPEHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"SIGMAHOME")
						SIGMAHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"METAMIXHOME")
						METAMIXHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"METAPHLAN2HOME")
						METAPHLAN2HOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"CONSTRAINSHOME")
						CONSTRAINSHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
				esac
			done
			statusband=$((statusband+1))
			cfileband=0
		fi
		
		if [ $((tifamilyband)) -eq 1 ]; then
			TIFAMILYFILE=$i
			tifamilyband=0
		fi
		
		if [ $((rfileband)) -eq 1 ]; then
			statusband=$((statusband+1))

			#first, we check if exist the pair end call.
			RFILE=$i
			rfileband=0
			READS=`echo "$i" |awk 'BEGIN{FS=","}{if($2 == ""){print "single"}else{print "paired"}}'`
		fi
		
		if [ $((dbpsband)) -eq 1 ]; then
			ok=`ls -1 $i* |wc -l |awk '{print $1}'`

			if [ $((ok)) -ge 1 ]; then
				DBPS=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				dbpsband=0
			else
				echo "$i file no exist"
				exit
			fi
		fi
		
		if [ $((dbm2band)) -eq 1 ]; then
			ok=`ls -1 $i* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBM2=$i
				dbm2band=0
			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmxband)) -eq 1 ]; then
			ok=`ls -1 $i* |wc -l |awk '{print $1}'`

			if [ $((ok)) -ge 1 ]; then
				DBMX=$i
				dbmx2band=0
			else
				echo "$i file no exist"
				exit
			fi
		fi


		if [ $((dbcsband)) -eq 1 ]; then
			ok=`ls -1 $i* |wc -l |awk '{print $1}'`

			if [ $((ok)) -ge 1 ]; then
				DBCS=$i
				dbcsband=0
			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((psfilterdb)) -eq 1 ]; then
				PSFDB=$i
				psfilterdb=0
		fi

		if [ $((dbmarkerband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				DBMARKER=$i
				dbmarkerband=0
			else
				echo "$i file no exist"
				exit
			fi
		fi
		
		if [ $((sigmacfileband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				sigmacfileband=0
				SIGMACFILE=$i
			else
				echo "$i file no exist"
				exit
			fi

		fi
	;;
	esac
done



#################################################
#This variables control the total procces to use

declare -A pids
i=0

#################################################

function coresControlFunction {
	if [ $((i)) -eq $((CORES)) ]; then
			for pid in ${pids[*]}
			do 
				wait $pid
				break 
			done
			i=$((i-1))
	fi
}

function pathoscopeFunction {

	coresControlFunction
	if [ "$DBPS" == "" ];then
		echo "you must provide a database for pathoscope"
	fi


		echo "wake up pathoscope"
		FILE=$RFILE

		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					PAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					PAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
					prior=`wc -l $PAIREND1 |awk '{print $1*2}'`
					perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$PAIREND1.fastq
					perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$PAIREND2.fastq
					RFILE=`echo "$PAIREND1.fastq,$PAIREND2.fastq"`
				else
					echo "$PAIREND2 doesn't exist"
					exit
				fi
			else
				echo "$PAIREND1 doesn't exist"
				exit
			fi	
		fi
		cd $TMPNAME
		if [ "$PSFDB" == "" ];then
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $IXDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED -numThreads $THREADS &
			pids[${i}]=$!
			i=$((i+1))
			SAMFILE=pathoscope_$RFILE.sam
		else
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $IXDIR -targetIndexPrefixes $DBPS -filterIndexPrefixes $PSFDB -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED -numThreads $THREADS &
			pids[${i}]=$!
			i=$((i+1))
			SAMFILE=pathoscope_$RFILE.sam
		fi

		
		cd ..
		TOCLEAN=$RFILE
		RFILE=$FILE

}

function metaphlanFunction {

	coresControlFunction
	FILE=$RFILE

	echo "wake up metaphlan"
	if [ "$READS" == "paired" ]; then
		PAIREND1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
		PAIREND2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
		#next, check the files (tolerance to missing files)
		if [ -f "$PAIREND1" ];then
			if [ -f "$PAIREND2" ];then
				PAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
				PAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
				perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$PAIREND1.fastq
				perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$PAIREND2.fastq
				RFILE=`echo "$PAIREND1.fastq,$PAIREND2.fastq"`
			else
				echo "$PAIREND2 doesn't exist"
				exit
			fi
		else
			echo "$PAIREND1 doesn't exist"
			exit
		fi	
	fi
	
	cd $TMPNAME
	
	AVIABLE=`echo "$CORES - $i" |bc`
	python ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$RFILE.bz2 --nproc $AVIABLE > ../metaphlan_$RFILE.dat
	
	cd ..
	TOCLEAN=$RFILE
	RFILE=$FILE

}

function metamixFunction {

		coresControlFunction

	if [ "$DBMX" == "" ];then
		echo "you must provide a database for pathoscope"
	fi

	if [ "$READS" == "paired" ]; then
		PAIREND1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
		PAIREND2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
		#next, check the files (tolerance to missing files)
		if [ -f "$PAIREND1" ];then
			if [ -f "$PAIREND2" ];then
				
				cp $PAIREND1 > $TMPNAME/.
				cp $PAIREND2 > $TMPNAME/.
				PAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
				PAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`

				cd $TMPNAME
				
				AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
				blastn -query $PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $AVIABLE -out blastOut$PAIREND1.tab &
				pids[${i}]=$!
				i=$((i+1))

				coresControlFunction
				
				AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
				blastn -query $PAIREND2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $AVAIBLE -out blastOut$PAIREND2.tab &
				pids[${i}]=$!
				i=$((i+1))

				cd ..
								
			else
				echo "$PAIREND2 doesn't exist"
				exit
			fi
		else
			echo "$PAIREND1 doesn't exist"
			exit
		fi
	else
		blastn -query $PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $AVIABLE -out blastOut$RFILE.tab &
	fi

	
}

function sigmaFunction {
											
	coresControlFunction
	AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
	cp $SIGMACFILE $TMPNAME/.
	$SIGMACFILE=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`

	cd $TMPNAME

	${SIGMAHOME}/./sigma-align-reads -c $SIGMACFILE -p $AVIABLE -w ../

	cd ..

}

function constrainsFunction {
 echo "constrains not yet"
}

function pathoscopeFunction2 {
	coresControlFunction
	echo "executing pathoscope ID module"
	cd $TMPNAME
	python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $prior &
	cd ..
}

function metamixFunction2 {
	coresControlFunction
	cd $TMPNAME
	if [ "$READS" == "paired" ]; then
		cat blastOut$PAIREND1.tab blastOut$PAIREND2.tab > blastOut$PAIREND1.$PAIREND2.tab
		rm blastOut$PAIREND1.tab blastOut$PAIREND2.tab
		mpirun -np 1 -quiet Rscript ${METAMIXHOME}/MetaMix.R blastOut$PAIREND1.$PAIREND2.tab ${METAMIXHOME}/names.dmp metamix_$RFILE_assignedReads.tsv &

	else
		mpirun -np 1 -quiet Rscript ${METAMIXHOME}/MetaMix.R blastOut$RFILE.tab ${METAMIXHOME}/names.dmp metamix_$RFILE.tsv &
	fi
	cd ..
}

function cleanFunction {
	wait $!
	if [ "$READS" == "paired" ]; then
		rm -f $TMPNAME/$PAIREND1.fastq $TMPNAME/$PAIREND2.fastq
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then
		rm -f *.sam
		rm -f $TMPNAME/pathoscope_$TOCLEAN.sam
	fi
	
	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		rm -f $TMPNAME/bowtieout$TOCLEAN.bz2
	fi
	if [[ "$METHOD" =~ "METAMIX" ]]; then
		rm -f $TMPNAME/blastOut$PAIREND1.$PAIREND2.tab
	fi
	if [[ "$METHOD" =~ "SIGMA" ]]; then
		rm -f sigma_out.html sigma_out.ipopt.txt sigma_out.qmatrix
	fi
	echo "Done :D"
}

#begin the code

if [ $((statusband)) -ge 2 ]; then

	#############################
	#checking critical variables#
	#############################

	if [ -d "$TMPNAME" ]; then
		echo "TMP folder exist, working in."
	else
		mkdir $TMPNAME
	fi

	if [ "$CORES" == "" ] || [ "$THREADS" == "" ]
	then
		echo "cores or threads are null, you must specify in the config file"
		exit
	fi

	if [[ "$ABSENT" =~ "yes" ]] ; then
		if [ "$tipermanent" == ""  ]; then
			echo "ABSENT=yes, but you don't especify the tax id of your permament genome, it's a requisite to apply perdonazo method"
			exit
		else
			curl -s "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id=$tipermanent" > tmp.xml
			FAMILYPERMANENT=`awk 'BEGIN{FS="[<|>]";prev=""}{if($2=="ScientificName"){prev=$3}if($3=="family"){printf "%s,",prev}}' tmp.xml` #family corresponding to fasta permament
			rm tmp.xml
		fi
	fi
	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		if [ "$DBM2" == "" ] || [ "$DBMARKER" == "" ];then
			echo "METAPHLAN is specify in the config file, but you must provide a database and pkl file in the command line"
			exit
		fi
	fi
	###############################
	###############################

	case $localband in
		"0")					
			echo "we working on no local mode :D (try --local)"
		;;
		"1")
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
					#REMEMBER HAVE DATABASE IN SIGMA FORMAT (each fasta in each directory)
						sigmaFunction
					;;
					"CONSTRAINS")
						constrainsFunction
					;;
				esac
			done
		;;
	esac

	###SECOND PART###
	echo "waiting for mapping work"
	wait $!
		case $localband in
		"0")					
			echo "we working on no local mode :D (try --local)"
		;;
		"1")
			for g in $METHOD
			do
				case $g in
					"PATHOSCOPE")
						pathoscopeFunction2
				   	;;
					"METAPHLAN")
						echo "metaphlan done"
					;;
					"METAMIX")
						metamixFunction2
					;;
					"SIGMA")
					#REMEMBER HAVE DATABASE IN SIGMA FORMAT (each fasta in each directory)
						echo "sigma done"
					;;
					"CONSTRAINS")
						echo "constrains done(?)"
					;;
				esac
			done
			cleanFunction
		;;
	esac

else
	echo "Invalid or Missing Parameters, print --help to see the options"
	echo "Usage: bash executionMethods --cfile [config file] --rfile [readsfile] -[dboption] [databases] --local (only if you use this module alone)"
	exit
fi