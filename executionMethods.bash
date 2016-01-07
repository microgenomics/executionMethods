#make sure you have installed correctly the patogen detection software 
set -e
export LANG="en_US.UTF-8"

cfileband=0
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
	"--dbmarker")
		dbmarkerband=1
	;;
	"--sigmacfile")
		sigmacfileband=1
	;;
	"--help")
		echo "#########################################################################################"
		echo -e "\nUsage: bash executionMethods --cfile [config file] --rfile [readsfile] -[dboption] [databases]"
		echo -e "\nOptions aviable:"
		echo "--cfile configuration file check README for more information"
		echo "--rfile reads file, if you have paired end reads, use: --rfile readfile1.fa,readfile2.fa"
		
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
				dbmxband=0
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

if [ -f /tmp/corescontrol ];then
	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
else
	i=0
fi
#################################################

function coresControlFunction {
if mkdir /tmp/lock; then
	if [ $((i)) -ge $((CORES)) ]; then
		band="foo"
		while [ "$band" != "" ];
		do
			firstpid=`head -n 1 /tmp/corescontrol |awk '{print $2}'`
			i=`head -n 1 /tmp/corescontrol |awk -v actual=$i '{print actual-$3}'`
			if [ "$firstpid" == "" ]; then
				band="foo"
			else
				echo "waiting for procces $firstpid"
				while kill -0 "$firstpid"; do
					sleep 5
				done				
				sed -i '' "1d" /tmp/corescontrol
				band=""
			fi

		done	
	fi
	rm -r /tmp/lock
else
	sleep 10
	coresControlFunction
fi
}

function pathoscopeFunction {

	if [ "$DBPS" == "" ];then
		echo "you must provide a database for pathoscope"
	else
		echo "wake up pathoscope"
		FILE=$RFILE

		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					NAMEPAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					NAMEPAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
					prior=`wc -l $PAIREND1 |awk '{print $1}'`
					
					if [ -f fasta_to_fastq.pl ]; then
						perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
						perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
					else
						fasta_to_fastqFunction 
						perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
						perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
					fi

					perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
					perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
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
			prior=`wc -l $RFILE |awk '{print $1/2}'`
			SINGLE=`echo "$RFILE" |rev |cut -d "/" -f 1 |rev`
			
			if [ -f fasta_to_fastq.pl ]; then
				perl ps_fasta_to_fastq.pl $RFILE > $TMPNAME/$SINGLE.fastq
				RFILE=$SINGLE.fastq
			else
				fasta_to_fastqFunction
				perl ps_fasta_to_fastq.pl $RFILE > $TMPNAME/$SINGLE.fastq
				RFILE=$SINGLE.fastq
			fi

		fi

		cd $TMPNAME
	
		i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
		coresControlFunction


		if [ "$PSFDB" == "" ];then
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $IXDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		else
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $IXDIR -targetIndexPrefixes $DBPS -filterIndexPrefixes $PSFDB -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		fi
		
		i=$((i+1))
		echo "$i $lastpid 1" >> /tmp/corescontrol

		cd ..

		TOCLEAN=$RFILE
		RFILE=$FILE

	fi



}

function metaphlanFunction {

	if [ "$DBM2" == "" ];then
		echo "you must provide a database for metaphlan"
	else
		FILE=$RFILE

		echo "wake up metaphlan"
		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					NAMEPAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					NAMEPAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`

					if [ -f fasta_to_fastq.pl ]; then
						perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
						perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
					else
						fasta_to_fastqFunction 
						perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
						perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
					fi
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
			if [ -f fasta_to_fastq.pl ]; then
				perl ps_fasta_to_fastq.pl $RFILE > $TMPNAME/$SINGLE.fastq
				RFILE=$SINGLE.fastq
			else
				fasta_to_fastqFunction
				perl ps_fasta_to_fastq.pl $RFILE > $TMPNAME/$SINGLE.fastq
				RFILE=$SINGLE.fastq
			fi
		fi
		
		cd $TMPNAME
		i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
		coresControlFunction

		AVIABLE=`echo "$CORES - $i" |bc`
		python ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$RFILE.bz2 --nproc $AVIABLE > ../metaphlan_$RFILE.dat &
		lastpid=$!
		i=$CORES

		cd ..

		echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

		TOCLEAN=$RFILE
		RFILE=$FILE
	fi

}

function metamixFunction {

	if [ "$DBMX" == "" ];then
		echo "you must provide a database for metamix"
	else
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
					
					i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
					coresControlFunction
				
					AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
					blastn -query $PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $AVIABLE -out blastOut$PAIREND1.tab &
					lastpid=$!
					i=$CORES

			        echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

					i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
					coresControlFunction
					
					AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
					blastn -query $PAIREND2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $AVAIBLE -out blastOut$PAIREND2.tab &
					lastpid=$!
					i=$CORES

			        echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

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
			cd $TMPNAME
			
			i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
			coresControlFunction
	
			AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
			blastn -query $PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $AVIABLE -out blastOut$RFILE.tab &
			lastpid=$!
			i=$CORES

			cd ..
			echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol
		fi
	fi



	
}

function sigmaFunction {
											
	cp $SIGMACFILE $TMPNAME/.
	$SIGMACFILE=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`

	cd $TMPNAME
	
	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	coresControlFunction	
	AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`

	${SIGMAHOME}/./sigma-align-reads -c $SIGMACFILE -p $AVIABLE -w ../
	lastpid=$!

	i=$CORES
	
	cd ..
        echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

}

function constrainsFunction {
 echo "constrains not yet"
}

function pathoscopeFunction2 {
	echo "executing pathoscope ID module"
	cd $TMPNAME

	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	coresControlFunction	

	python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $prior &
	lastpid=$!

	i=$((i+1))
	echo "$i $lastpid 1" >> /tmp/corescontrol

	cd ..

}

function metamixFunction2 {
	cd $TMPNAME

	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	coresControlFunction

	if [ "$READS" == "paired" ]; then
		cat blastOut$PAIREND1.tab blastOut$PAIREND2.tab > blastOut$PAIREND1.$PAIREND2.tab
		rm blastOut$PAIREND1.tab blastOut$PAIREND2.tab

		mpirun -np 1 -quiet Rscript ${METAMIXHOME}/MetaMix.R blastOut$PAIREND1.$PAIREND2.tab ${METAMIXHOME}/names.dmp metamix_$RFILE_assignedReads.tsv &
		lastpid=$!


	else
		mpirun -np 1 -quiet Rscript ${METAMIXHOME}/MetaMix.R blastOut$RFILE.tab ${METAMIXHOME}/names.dmp metamix_$RFILE.tsv &
		lastpid=$!

	fi
    i=$((i+1))
    echo "$i $lastpid 1" >> /tmp/corescontrol

    cd ..

}

function cleanFunction {
	wait $!

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
		rm -f $TMPNAME/blastOut$PAIREND1.$PAIREND2.tab
	fi
	if [[ "$METHOD" =~ "SIGMA" ]]; then
		rm -f sigma_out.html sigma_out.ipopt.txt sigma_out.qmatrix
	fi
	echo "Done :D"
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

#begin the code

if [ $((statusband)) -ge 2 ]; then

	#############################
	#checking critical variables#
	#############################

	if [ "$CORES" == "" ] || [ "$THREADS" == "" ]
	then
		echo "cores or threads are null, you must specify in the config file"
		exit
	fi

	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		if [ "$DBM2" == "" ] || [ "$DBMARKER" == "" ];then
			echo "METAPHLAN is specify in the config file, but you must provide a database and pkl file in the command line"
			exit
		fi
	fi
	###############################
	###############################

			if [ -d "$TMPNAME" ]; then
				echo "TMP folder exist, working in."
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
						constrainsFunction
					;;
				esac
			done
		
	###SECOND PART###
	echo "waiting for mapping work"
	wait $!

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

else
	echo "Invalid or Missing Parameters, print --help to see the options"
	echo "Usage: bash executionMethods --cfile [config file] --rfile [readsfile] -[dboption] [databases]"
	exit
fi
