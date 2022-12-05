#!/bin/bash

dir="/mnt/nas/yh/11.WGS"


#replace sample_ID
for k in PQ111A01 PQ111A03 PQ111A04
	
	do
	
	sampleID=$(ls -h $dir/$k/5.QC/ |tr " " "\t"| cut -f 1 | uniq | grep "WQG")
		
		for s in $sampleID
			
			do

			#json="_R1_merged.fastq.gz_fastp.gz.json"
			#alignment="_R1_merged.fastq.gz.bam_alignment_metrics"
			#HQ="_R1_merged.fastq.gz_HQ_dedup_metrics"
			#wgs="_R1_merged.fastq.gz.bam_wgs_metrics"
			
			rdir="/mnt/nas/yh/11.WGS/$k/5.QC/$s"
			
			#replace
			mv $rdir/${s}_R1_merged.fastq.gz_fastp.gz.json $rdir/${s}_R1.fq.gz_fastp.gz.json
			mv $rdir/${s}_R1_merged.fastq.gz.bam_alignment_metrics $rdir/${s}_R1.fq.gz.bam_alignment_metrics
			mv $rdir/${s}_R1_merged.fastq.gz_HQ_dedup_metrics $rdir/${s}_R1.fq.gz_HQ_dedup_metrics
			mv $rdir/${s}_R1_merged.fastq.gz.bam_wgs_metrics $rdir/${s}_R1.fq.gz.bam_wgs_metrics
			done &
done 
wait


#catch QC data

plID=$(ls -h $dir/ |tr " " "\t"| cut -f 1 | uniq | grep "PQ")

for p in $plID 

	do

	list=$(ls -h $dir/$p/5.QC/ |tr " " "\t"| cut -f 1 | uniq | grep "WQG")

		for l in $list

			do

			wdir="/mnt/nas/yh/11.WGS/$p/5.QC/$l"
			echo ${l} > $wdir/${l}_QC2.txt
			
			##Total reads
			grep -A 2 "\"before_filtering"\" \
			$wdir/${l}_R1.fq.gz_fastp.gz.json \
			| grep "\"total_reads"\" \
			| echo $(awk '{gsub(/^\s+|,|"/, "");print}') \
			| tr ":" "\t" \
			| cut -f 2 \
			| echo "Total_reads:" $(awk '{print}') \
			>> $wdir/${l}_QC2.txt

			##Total pair reads
			grep -A 2 "\"before_filtering"\" \
			$wdir/${l}_R1.fq.gz_fastp.gz.json \
			| grep "\"total_reads"\" \
			| echo $(awk '{gsub(/^\s+|,|"/, "");print}') \
			| tr ":" "\t" \
			|cut -f 2 \
			| echo "Total_pair_reads:" $(awk '{print $1/2}') \
			>>$wdir/${l}_QC2.txt

			##Total reads passed q20
			grep -A 2 "\"after_filtering"\" \
			$wdir/${l}_R1.fq.gz_fastp.gz.json \
			| grep "\"total_reads"\" \
			| echo $(awk '{gsub(/^\s+|,|"/, "");print}') \
                        | tr ":" "\t" \
                        | cut -f 2 \
			| echo "Total_reads_passed_q20:" $(awk '{print}') \
			>>$wdir/${l}_QC2.txt

			##Total mapped reads
			grep "^PAIR" \
			$wdir/${l}_R1.fq.gz.bam_alignment_metrics \
			| echo "Total_mapped_reads:" $(awk '{print $6}') \
			>>$wdir/${l}_QC2.txt



			##Total uniquely mapped reads
			awk '{print $4}' $wdir/${l}_R1.fq.gz_HQ_dedup_metrics \
			| sed -n "7,8p" \
			| echo $(sed -z 's/\n/ /g') \
			| echo 'Total_uniquely_mapped_reads:' $(awk '{print $2*2}') \
			>> $wdir/${l}_QC2.txt


			##Redundancy
			awk '{print $10}' $wdir/${l}_R1.fq.gz_HQ_dedup_metrics \
			| sed -n "7,8p" \
			| echo $(sed -z 's/\n/ /g') \
			| echo 'Redundancy:' $(awk '{print $2*100}') '%' \
			>> $wdir/${l}_QC2.txt

			##Coverage
			awk '{print $2}' $wdir/${l}_R1.fq.gz.bam_wgs_metrics \
			| sed -n "8p" \
			| echo 'Coverage:' $(awk '{print}') \
			>>  $wdir/${l}_QC2.txt
			done &
			wait
		
		##pooling data
		for c in $list
			
			do
			 
			wdir="/mnt/nas/yh/11.WGS/$p/5.QC/$c"
			
			cat $wdir/${c}_QC2.txt >> $dir/QCpool.txt
		done &
done
wait


#excel f

for q in Coverage Total_reads: Total_pair_reads Total_reads_passed_q20 Total_mapped_reads Total_uniquely_mapped_reads Redundancy

	do
	
	grep $q $dir/QCpool.txt \
	| tr ":" "\t" \
	| cut -f 2 \
	 > $dir/${q%:}.txt
	
	sed -i "1 i ${q%:}" $dir/${q%:}.txt
done &
wait 


grep "WQG" $dir/QCpool.txt > $dir/ID.txt
sed -i '1 i Sample_ID' $dir/ID.txt
wait

paste $dir/ID.txt $dir/Coverage.txt $dir/Total_reads.txt $dir/Total_pair_reads.txt $dir/Total_reads_passed_q20.txt $dir/Total_mapped_reads.txt $dir/Total_uniquely_mapped_reads.txt $dir/Redundancy.txt > $dir/QCexcel.txt
wait

sed -i 's/_/ /g' $dir/QCexcel.txt
wait
