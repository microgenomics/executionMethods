#make sure you have installed correctly the patogen detection software 
set -ex

cfileband=0
statusband=0
rfileband=0
dbpsband=0
dbm2band=0
dbmxband=0
mxnamesband=0
psfilterdb=0
dbmarkerband=0
sigmacfileband=0
csfileband=0
dbsgband=0
PSFDB=""
TOCLEAN=""
SIGMACFILE=""
TMPNAME="TMP_FOLDER"

INITIALPATH=`pwd`

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
	"--PSfilterdb")
		psfilterdb=1
	;;
	"--dbM2")
		dbm2band=1
	;;
	"--dbmarker")
		dbmarkerband=1
	;;
	"--dbMX")
		dbmxband=1
	;;
	"--MXnames")
		mxnamesband=1
	;;
	"--sigmacfile")
		sigmacfileband=1
	;;
	"--dbSG")
		dbsgband=1
	;;
	"--csfile")
		csfileband=1
	;;
	"--help")
		echo "#########################################################################################"
		echo -e "\nUsage: bash executionMethods --cfile [config file] --rfile [readsfile] -[DB options] [databases]"
		echo -e "\nOptions aviable:"
		echo "--cfile configuration file check README for more information"
		echo "--rfile reads file, if you have paired end reads, use: --rfile readfile1.fa,readfile2.fa"
		
		echo "--PSfilterdb pathoscope filter databases prefix"
		echo "--dbmarker is the pkl file used by metaphlan, if you don't use metaphlan, don't use this flag (full path)"
		echo "--sigmacfile is the configuration file used by sigma, if in your cfile, SIGMA is in the METHODS flag, you must provide the sigmacfile"
		
		echo -e "\nDB options:"
		echo "--dbPS pathoscope database folder and prefix: e.g /home/user/dbpathoscope_bt2/targetdb (bowtie2 index)"
		echo "--dbM2 metaphlan database folder and prefix: e.g /home/user/dbmarkers_bt2/targetdb (bowtie2 index)"
		echo "--dbMX metamix database folder and prefix: e.g /home/user/dbmetamix_nhi/targetdb (blast index)"
		echo "--MXnames metamix names translation, is a file with format 'ti name'"
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
					"METHOD")
						METHOD=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
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
					"BLASTHOME")
						BLASTHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"METAPHLAN2HOME")
						METAPHLAN2HOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"CONSTRAINSHOME")
						CONSTRAINSHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"SAMTOOLSHOME")
						SAMTOOLSHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"BOWTIE2HOME")
						BOWTIE2HOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
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

			#first, we check if exist the pair end call.
			IRFILE=$i
			rfileband=0
			READS=`echo "$i" |awk 'BEGIN{FS=","}{if($2 == ""){print "single"}else{print "paired"}}'`
		fi
		
		if [ $((dbpsband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBPS=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				dbpsband=0
				statusband=$((statusband+1))
			else
					echo "$i file no exist"
					exit
			fi
		fi
		
		if [ $((dbm2band)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBM2=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				DBM2=`echo "$dbpath/$DBM2"`
				dbm2band=0
			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmxband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBMX=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				DBMX=`echo "$dbpath/$DBMX"`
				dbmxband=0
			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((mxnamesband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				MXNAMES=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				MXNAMES=`echo "$dbpath/$MXNAMES"`
				mxnamesband=0
			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((psfilterdb)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				PSFDB=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				PSFDB=`echo "$dbpath/$PSFDB"`
				psfilterdb=0
			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmarkerband)) -eq 1 ]; then
			if [ -f $i ]; then
				DBMARKER=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				DBMARKER=`echo "$dbpath/$DBMARKER"`
				dbmarkerband=0
			else
				echo "$i file no exist"
				exit
			fi
		fi
		
		if [ $((sigmacfileband)) -eq 1 ]; then
			if [ -f $i ]; then
				SIGMACFILE=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				SIGMACFILE=`echo "$dbpath/$SIGMACFILE"`
				sigmacfileband=0
			else
				echo "$i file no exist"
				exit
			fi

		fi

		if [ $((dbsgband)) -eq 1 ]; then
			if [ -d $i ]; then
				DBSG=$i
				dbsgband=0
			else
				echo "$i master directory no exist"
				exit
			fi

		fi

		if [ $((csfileband)) -eq 1 ]; then
			if [ -f $i ]; then
				CSFILE=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $IXDIR
				dbpath=`pwd`
				CSFILE=`echo "$dbpath/$CSFILE"`
				csfileband=1
			else
				echo "$i file no exist"
				exit
			fi
		fi

	;;
	esac
done

#################################################
declare -A pids
i=0
maxexe=5
#################################################
lastpid=0
function coresControlFunction {
if mkdir /tmp/lock; then
	if [ $((i)) -ge $((maxexe)) ]; then
		wait $lastpid
		i=$((i-1))

#		band="foo"
#		while [ "$band" != "" ];
#		do
#			firstpid=`head -n 1 /tmp/corescontrol |awk '{print $2}'`
#			i=`head -n 1 /tmp/corescontrol |awk -v actual=$i '{print actual-$3}'`
#			if [ "$firstpid" == "" ]; then
#				band="foo"
#			else
#				echo "waiting for procces $firstpid"
#				while kill -0 "$firstpid"; do
#					sleep 5
#				done			
#				sed -i '' "1d" /tmp/corescontrol
#				band=""
#			fi
#		done
	fi
	rm -r /tmp/lock
else
	sleep 10
	coresControlFunction
fi
}
function fastalockFunction {
	if mkdir fastalock; then
		echo "fastalock created"
	else
		sleep 10
		fastalockFunction
	fi
}
function fastaunlockFunction {
	rm -r fastalock

}
function readstoFastqFunction {
			if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					NAMEPAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					NAMEPAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`

					fastalockFunction
					if [ -f fasta_to_fastq.pl ]; then
						if [ ! -f $TMPNAME/$NAMEPAIREND1.fastq ];then
							perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq &
							perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq &
							wait $!
						fi
					else
						fasta_to_fastqFunction 
						if [ ! -f $TMPNAME/$NAMEPAIREND1.fastq ];then
							perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq &
							perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq &
							wait $!
						fi
					fi
					fastaunlockFunction

					RFILE=`echo "$NAMEPAIREND1.fastq,$NAMEPAIREND2.fastq"`
				else
					echo "$PAIREND2 doesn't exist"
					exit
				fi
			else
				echo "$PAIREND1 doesn't exist"
				exit
			fi
		else
			fastalockFunction
			if [ -f fasta_to_fastq.pl ]; then
				if [ ! -f $TMPNAME/$SINGLE.fastq ];then
					perl ps_fasta_to_fastq.pl $IRFILE > $TMPNAME/$SINGLE.fastq
					RFILE=$SINGLE.fastq
				fi
			else
				fasta_to_fastqFunction
				if [ ! -f $TMPNAME/$SINGLE.fastq ];then
					perl ps_fasta_to_fastq.pl $IRFILE > $TMPNAME/$SINGLE.fastq
					RFILE=$SINGLE.fastq
				fi
			fi
			fastaunlockFunction
		fi
}
function pathoscopeFunction {

		echo "wake up pathoscope"
		FILE=$IRFILE

		readstoFastqFunction

		cd $TMPNAME
	
		#if [ -f /tmp/corescontrol ];then
		#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
		#else
		#	i=0
		#fi		

		coresControlFunction
	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`


		if [ "$PSFDB" == "" ];then
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $IXDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		else
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $IXDIR -targetIndexPrefixes $DBPS -filterIndexPrefixes $PSFDB -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		fi
		pids[${i}]=$lastpid
		i=$((i+1))
		#echo "$i $lastpid 1" >> /tmp/corescontrol

		cd ..

		TOCLEAN=$RFILE
		IRFILE=$FILE

 
}

function metaphlanFunction {

		FILE=$IRFILE

		echo "wake up metaphlan"
		readstoFastqFunction
		
		cd $TMPNAME
		#if [ -f /tmp/corescontrol ];then
		#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
		#else
		#	i=0
		#fi	
		coresControlFunction
	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`

		python ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$RFILE.bz2 --nproc $CORES > ../metaphlan_$RFILE.dat &
		lastpid=$!
		#i=$CORES
		pids[${i}]=$lastpid		
		i=$((i+1))

		cd ..

		#echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

		TOCLEAN=$RFILE
		IRFILE=$FILE

}

function metamixFunction {

		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					
					P1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					P2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
					
					if mkdir $TMPNAME/metamix_$P1.$P2; then #we make new folder because is easier to clean after execution
						cp $PAIREND1 $TMPNAME/metamix_$P1.$P2/$P1
						cp $PAIREND2 $TMPNAME/metamix_$P1.$P2/$P2
					else
						echo "Metamix: cleaning previous run"
						rm -r $TMPNAME/metamix_$P1.$P2
						mkdir $TMPNAME/metamix_$P1.$P2
						cp $PAIREND1 $TMPNAME/metamix_$P1.$P2/$P1
						cp $PAIREND2 $TMPNAME/metamix_$P1.$P2/$P2
					fi

					cd $TMPNAME
					cd metamix_$P1.$P2
					
					#if [ -f /tmp/corescontrol ];then
					#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
					#else
					#	i=0
					#fi	
					coresControlFunction
					#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`

					${BLASTHOME}/blastn -query $P1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $CORES -out blastOut$P1.tab &
					lastpid=$!
					pids[${i}]=$lastpid
					i=$((i+1))

			       # echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

					#i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
					coresControlFunction
						#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`

					${BLASTHOME}/blastn -query $P2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $CORES -out blastOut$P2.tab &
					lastpid=$!
					pids[${i}]=$lastpid
					i=$((i+1))

			        #echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol
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

			if mkdir $TMPNAME/metamix_$SINGLE; then #we make new folder because is easier to clean after execution
				cp $IRFILE $TMPNAME/metamix_$SINGLE/$SINGLE
			else
				echo "Metamix: cleaning previous run"
				rm -r $TMPNAME/metamix_$SINGLE
				mkdir $TMPNAME/metamix_$SINGLE
				cp $IRFILE $TMPNAME/metamix_$SINGLE/$SINGLE
			fi

			cd $TMPNAME
			cd metamix_$SINGLE
			#if [ -f /tmp/corescontrol ];then
			#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
			#else
			#	i=0
			#fi	
			coresControlFunction
		#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`

			blastn -query $SINGLE -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $CORES -out blastOut$SINGLE.tab &
			lastpid=$!
			pids[${i}]=$lastpid
			i=$((i+1))

			cd ..
			cd ..
			#echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol
		fi
	
}

function sigmaFunction {

	echo "wake up sigma"
	cd $TMPNAME

	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi	
	coresControlFunction	
	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
	if [ "$RTYPE" == "PAIRED" ];then
		SGTOCLEAN=sigma_$RFILE
		if mkdir $SGTOCLEAN ;then
			cd $SGTOCLEAN
		else
			echo "sigma: cleaning previous run"
			rm -rf $SGTOCLEAN
			mkdir $SGTOCLEAN
			cd $SGTOCLEAN
		fi
	else
		SGTOCLEAN=sigma_$RFILE
		if mkdir $SGTOCLEAN ;then
			cd $SGTOCLEAN
		else
			echo "sigma: cleaning previous run"
			rm -rf $SGTOCLEAN
			mkdir $SGTOCLEAN
			cd $SGTOCLEAN
		fi
	fi
	mv ../$SIGMACFILE .
	${SIGMAHOME}/./sigma-align-reads -c $SIGMACFILE -p $CORES -w . &
	lastpid=$!
	pids[${i}]=$lastpid
	i=$((i+1))

	cd ..
	cd ..
    #echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

}

function pathoscopeFunction2 {
	echo "executing pathoscope ID module"
	cd $TMPNAME

	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi
	coresControlFunction	

	python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $prior &
	lastpid=$!
	pids[${i}]=$lastpid
	i=$((i+1))
	#echo "$i $lastpid 1" >> /tmp/corescontrol

	cd ..

}

function metamixFunction2 {

	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi
	coresControlFunction
	cd $TMPNAME
	trys=10
	metamixCodeFunction
	echo "execute metamix R function"

		if [ "$READS" == "paired" ]; then
			cd metamix_$P1.$P2
			BACKUPNAME=`echo "metamix_$P1.$P2"`

			cat blastOut$P1.tab blastOut$P2.tab > blastOut$P1.$P2.tab
			rm blastOut$P1.tab blastOut$P2.tab

			while [ $((trys)) -ge 1 ]
			do
				if Rscript ../MetaMix.R blastOut$P1.$P2.tab $MXNAMES ;then
					mv presentSpecies_assignedReads.tsv ../../$BACKUPNAME.assignedReads.tsv
					break
					echo "metamix execution successful"
				else
					trys=$((trys-1))
					echo "metamix execution failed, ($trys retryings left)"
				fi
			done

			cd ..

		else
			cd metamix_$SINGLE
			while [ $((trys)) -ge 1 ]
			do
				if Rscript ../MetaMix.R blastOut$SINGLE.tab $MXNAMES ;then
					mv presentSpecies_assignedReads.tsv ../../metamix_$SINGLE.tsv
					break
					echo "metamix execution successful"
				else
					trys=$((trys-1))
					echo "metamix execution failed, ($trys retryings left)"
				fi
			done

			cd ..
		fi

		if [ $((trys)) -eq 0 ];then
			foldererror=`pwd`
			echo "error: Metamix execution not finished in $foldererror"
		fi

		cd ..


    #echo "$i $lastpid 1" >> /tmp/corescontrol

}
function sigmaFunction2 {
	cd $TMPNAME 
	cd $SGTOCLEAN

	echo "executing sigma wrapper module"	
	${SIGMAHOME}/./sigma -c $SIGMACFILE -t $THREADS -w . &

	lastpid=$!
	pids[${i}]=$lastpid
	i=$((i+1))
	cd ..
	cd ..

}

function constrainsFunction {


	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi
	readstoFastqFunction

	cd $TMPNAME
	coresControlFunction

	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`	CSTOCLEAN=constrains_$RFILE
	if [ -f "../metaphlan_$RFILE.dat" ];then
		CSERROR=0
		CSTOCLEAN=constrains_$RFILE

		if [ "$READS" == "paired" ]; then
			F1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
			F2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
			echo "sample: $RFILE
			fq1: $F1
			fq2: $F2
			metaphlan: ../metaphlan_$RFILE.dat" > cs_config_$RFILE.conf
		else
			echo "sample: $RFILE 
			fq: $RFILE
			metaphlan: ../metaphlan_$RFILE.dat" > cs_config_$RFILE.conf
			CSTOCLEAN=constrains_$RFILE
		fi
			python ${CONSTRAINSHOME}/ConStrains.py -c cs_config_$RFILE.conf -o $CSTOCLEAN -t $CORES -d ${CONSTRAINSHOME}/db/ref_db -g ${CONSTRAINSHOME}/db/gsize.db --bowtie2=${BOWTIE2HOME}/bowtie2-build --samtools=${SAMTOOLSHOME}/samtools -m ${METAPHLAN2HOME}/metaphlan2.py &
			lastpid=$!
			pids[${i}]=$lastpid
			i=$((i+1))
	else
			echo "Constrains: no metaphlan2 file found, impossible continue"
			CSERROR=1
	fi
	cd ..

			
}

function sigmaCfileFunction {

	if [ "$READS" == "paired" ]; then
		F1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
		SIZE=`tail -n1 $F1 |wc |awk '{print $3}'`
		F1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}' |rev |cut -d "/" -f 1 |rev`
		F1=`echo "$F1.fastq"`
		F2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}' |rev |cut -d "/" -f 1 |rev`
		F2=`echo "$F2.fastq"`
		
		readstoFastqFunction
		cd $TMPNAME	
		FASTQFOLDER=`pwd`
		cd ..
		RFILE=`echo "$F1,$F2"`
		#RFILE=`echo "$F1,$F2"`
		
		echo "[Program_Info]
Bowtie_Directory=$BOWTIE2HOME
Samtools_Directory=$SAMTOOLSHOME
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
		readstoFastqFunction
		RFILE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`
		RFILE=`echo "$IRFILE.fastq"`
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
function lastStepFunction {

	rm -f $TMPNAME/fasta_to_fastq.pl

	if [ "$READS" == "paired" ]; then
		rm -f $TMPNAME/$NAMEPAIREND1.fastq $TMPNAME/$NAMEPAIREND2.fastq
	else
		rm -f $TMPNAME/$TOCLEAN.fastq
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then
		rm -f updated_pathoscope_$TOCLEAN.sam
		rm -f $TMPNAME/$SAMFILE
	fi
	
	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		rm -f $TMPNAME/bowtieout$TOCLEAN.bz2
	fi
	
	if [[ "$METHOD" =~ "METAMIX" ]]; then
		#rm -f $TMPNAME/MetaMix.R
		if [ "$READS" == "paired" ]; then
			rm -rf $TMPNAME/metamix_$P1.$P2
		else
			rm -rf $TMPNAME/metamix_$SINGLE
		fi
	fi
	
	if [[ "$METHOD" =~ "SIGMA" ]]; then
		mv $TMPNAME/$SGTOCLEAN/*.gvector.txt $SGTOCLEAN.gvector.txt
		rm -rf $TMPNAME/$SGTOCLEAN
	fi

	if [[ "$METHOD" =~ "CONSTRAINS" ]] && [ "$CSERROR" -eq 0 ]; then
		mv $TMPNAME/$CSTOCLEAN/results/Overall_rel_ab.profiles $CSTOCLEAN.profiles
		rm -rf $TMPNAME/$CSTOCLEAN
		rm -rf $TMPNAME/cs_config_$RFILE.conf
	fi

	echo "Done :D"
}

function criticalvariablesFunction {
	pass=0
	errormessage=""

	if [ "$IRFILE" == "" ];then
		errormessage=`echo -e "$errormessage You must provide a read file\n"`
		pass=$((pass+1))
	fi

	if [ "$CORES" == "" ] || [ "$THREADS" == "" ]
	then
		errormessage=`echo -e "$errormessage cores or threads are null, you must specify in the config file\n"`
		pass=$((pass+1))
	fi

	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		if [ "$DBM2" == "" ] || [ "$DBMARKER" == "" ];then
			errormessage=`echo -e "$errormessage METAPHLAN is specify in the config file, but you must provide a database (bowtie2 index), and pkl file in the command line (--dbM2 and --dbmarker)\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then

		if [ "$DBPS" == "" ];then
			errormessage=`echo -e "$errormessage You must provide a database (bowtie2 index), for pathoscope (--dbPS)\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "METAMIX" ]]; then

		if [ "$DBMX" == "" ];then
			errormessage=`echo -e "$errormessage You must provide a database (blast index), for metamix (--dbMX)\n"`
			pass=$((pass+1))
		fi

		if [ "$MXNAMES" == "" ];then
			errormessage=`echo -e "$errormessage You must provide the names of your blast database (--MXnames), this file have ti - name format (183214 Foo)\n"`
			pass=$((pass+1))
		fi

		if [ "$BLASTHOME" == "" ];then
			errormessage=`echo -e "$errormessage You must provide BLASTHOME in config file (e.g /usr/local/ncbi/blast/bin)\n"`
			pass=$((pass+1))
		fi
	fi

#	if [[ "$METHOD" =~ "CONSTRAINS" ]]; then
#		if [[ ! "$METHOD" =~ "METAPHLAN" ]]; then
#			errormessage=`echo -e "$errormessage METAPHLAN is needed to CONSTRAINS work\n"`
#			pass=$((pass+1))
#		fi
#	fi

	if [[ "$METHOD" =~ "SIGMA" ]]; then

		if [ "$SIGMACFILE" == "" ];then

			if [ "$BOWTIE2HOME" == "" ];then
				errormessage=`echo -e "$errormessage you must provide a bowtie2 home in config file (BOWTIE2HOME flag), to generate sigma config file\n"`
				pass=$((pass+1))
			fi
			
			if [ "$SAMTOOLSHOME" == "" ];then
				errormessage=`echo -e "$errormessage you must provide a samtools home/bin (SAMTOOLSHOME flag), to generate sigma config file\n"`
				pass=$((pass+1))
			fi

			if [ "$DBSG" == "" ]; then
				errormessage=`echo -e "$errormessage you must provide a samtools home/bin (SAMTOOLSHOME flag), to generate sigma config file\n"`
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
				echo "$errormessage"
				exit
			fi

		else

			DBSG=`grep -1 "Reference_Genome_Directory" $SIGMACFILE |cut -d "=" -f 2`
			PR1=`grep -1 "Paired_End_Reads_1" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`
			PR2=`grep -1 "Paired_End_Reads_2" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`
			SR=`grep -1 "Single_End_Reads" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`

			if [ -d $DBSG ];then
					errormessage=`echo -e "$errormessage you must provide a database folder in sigma config file\n"`
					pass=$((pass+1))
			fi
			if [ "$SR" == "" ];then
				if [ "$PR1" == "" ] || [ "$PR2" == "" ]; then
					errormessage=`echo -e "$errormessage you must provide a read file in sigma config file\n"`
					pass=$((pass+1))
				else
					RTYPE="PAIRED"
				fi
			else
				RTYPE="SINGLE"
			fi
		fi
	fi

	if [ $((pass)) -eq 0 ];then
		echo "all parameters ok"
	else
		echo "$errormessage"
		exit
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
	echo 'args<-commandArgs()
	blastab<-c(args[6])
	names<-c(args[7])

	require(metaMix)
	library(methods)

	###############################
	print("execute Step1")
	Step1<-generative.prob.nucl(blast.output.file=blastab,blast.default=FALSE,outDir=".")
	print("execute Step2")
	Step2 <- reduce.space(step1=Step1)
	print("execute Step3")
	Step3<-parallel.temper(step2=Step2)
	print("execute Step4")
	step4<-bayes.model.aver(step2=Step2, step3=Step3, taxon.name.map=names)' > MetaMix.R
}

#begin the code

if [ $((statusband)) -ge 1 ]; then
cd $INITIALPATH
#Check some parameters before do something
criticalvariablesFunction

			if [ -d "$TMPNAME" ]; then
				echo "$TMPNAME exist, working in."
			else
				mkdir $TMPNAME
			fi

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
						#waiting for metaphlan work
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
			declare -A pids
			i=0
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
						metamixFunction2 #bottleneck, put metamix in the last of methods e.g. METHODS=SIGMA,CONSTRAINS,METAMIX
					;;
					"SIGMA")
					#REMEMBER HAVE DATABASE IN SIGMA FORMAT (each fasta in each directory, and each name folder must be the gi number of fasta that contain)
						sigmaFunction2
					;;
					"CONSTRAINS")
						constrainsFunction
					;;
				esac
			done
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
