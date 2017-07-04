
#!/bin/bash


gr='\033[1;32m'
re='\033[1;31m'
xx='\033[0m'
yw='\033[1;33m'
bl='\033[0;34m'

show(){
printf "${!1}\n"
}

acc1="Avoid the use of the root account."
acc2="Ensure MFA is enabled for all IAM users that have a console password."
acc3="Ensure credentials unused for 90 days or greater are disabled."
acc4="Ensure access keys are rotated every 90 days or less."
acc5="Ensure IAM password policy requires at least one uppercase letter."
acc6="Ensure IAM password policy requires at least one lowercase letter."

log1="Ensure CloudTrail is enabled in all regions:"
log2="Ensure CloudTrail log file validation is enabled:"
log3="Ensure the S3 bucket CloudTrail logs to is not publicly accessible:"
log4="Ensure CloudTrail trails are integrated with CloudWatch logs:"
log5="Ensure AWS Config is enabled in all regions:"
log6="Ensure S3 bucket access logging is enabled on the CloudTrail S3 bucket:"
log7="Ensure CloudTrail logs are encrypted at rest using KMS CMKs:"
log8="Ensure rotation for customer created CMKs is enabled:"


#echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo "   ______     ______     __  __     ______"    
echo "  /\___  \   /\  ___\   /\ \/\ \   /\  ___\ "   
echo "  \/_/  /__  \ \  __\   \ \ \_\ \  \ \___  \ "  
echo "    /\_____\  \ \_____\  \ \_____\  \/\_____\ " 
echo "    \/_____/   \/_____/   \/_____/   \/_____/ "
echo -en '\n'
#echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo -en '\n'
echo -e "____________________________________________"
echo -en '\n'
echo -e "${bl}AWS Auditing & Hardening Tool v1.0 ~${xx}"
echo -en '\n'
echo -e "${re}denizparlak@papilon.com.tr${xx}"
echo -e "${re}twitter.com/_denizparlak${xx}"
echo -en '\n'
echo -e "Zeus is starting at.." `date`
#echo -en '\n'
echo -e "____________________________________________"
echo -en '\n'

check_aws(){

type "$1" &> /dev/null

}

check_pip(){

type "$1" &> /dev/null 

}

check_os(){

if [[ $OSTYPE == darwin* ]]
then
echo -e "${yw}INFO${xx}: Operating System: MacOS"
if check_pip pip ; then
echo -e "${yw}INFO{$xx}: pip is installed on the system."
else
curl -O https://bootstrap.pypa.io/get-pip.py &> /dev/null
python3 get-pip.py --user &> /dev/null
fi
if check_aws aws ; then
echo -e "${yw}INFO${xx}: AWS-CLI is installed on the system."
else
pip3 install --user --upgrade awscli &> /dev/null
fi
echo ""
elif [[ "$OSTYPE" == linux* ]]
then
echo -e "${yw}INFO${xx}: Operating System: Linux"
if check_pip pip; then
echo -e "${yw}INFO${xx}: pip is installed on the system."
else
pip install awscli --upgrade --user &> /dev/null
fi
if check_aws aws ; then
echo -e "${yw}INFO${xx}: AWS-CLI is installed on the system."
echo -e "____________________________________________"
echo -en '\n'
else
pip3 install --user --upgrade awscli &> /dev/null
fi
echo ""
fi

}

check_os


avoid_root(){

cre_rep=$(aws iam generate-credential-report)
aws iam get-credential-report --query 'Content' --output text | base64 -d | cut -d, -f1,5,11,16 > credential_reports.txt
echo -en "IAM credential report file created as 'credential_reports.txt'"
echo ""

}


show acc1
echo "Result:"
echo ""
avoid_root
echo ""
echo -e "____________________________________________"
echo -en '\n'


mfa_iam(){

aws iam get-credential-report --query 'Content' --output text | base64 -d | cut -d, -f1,4,8 > mfa_reports.txt

echo -en "MFA credential report file created as 'mfa_reports.txt'"
echo ""

}

show acc2
echo "Result:"
echo ""
mfa_iam
echo ""
echo -e "____________________________________________"
echo -en '\n'


days_90(){

rep_days=$(aws iam get-credential-report --query 'Content' --output text | base64 -d | cut -d, -f1,4,5,9,10,11,14,15,16 | awk -F "," '{print $2}' | sed -n '2p')

if [ "$rep_days" == "not_supported" ]
then
echo -e "${re}WARNING${xx}"
echo -e "Password not supported!"
else
echo -e "${gr}OK${xx}"
echo -e "Password enabled for each user!"
fi

}

show acc3
echo "Result:"
echo ""
days_90
echo ""
echo -e "____________________________________________"
echo -en '\n'

rotated_90(){

aws iam get-credential-report --query 'Content' --output text | base64 -d > access_key.log

echo -en "Access keys rotate log file created as access_key.log"
echo ""

}


show acc4
echo "Result:"
echo ""
rotated_90
echo ""
echo -e "____________________________________________"
echo -en '\n'


uppercase_iam(){

if aws iam get-account-password-policy | grep NoSuch
then
echo -en "${re}WARNING${xx}"
echo -en "Uppercase letter force was not setted for IAM password policy!"
read -p 'fix? y/n' fix_acc
if [ "$fix_acc" == "y" ]
then
aws iam update-account-password-policy --require-uppercase-charecters
fi
else
echo -en "${gr}OK${xx}"
echo ""
echo -en "Uppercase letter force active!"
fi

}

show acc5
echo "Result:"
echo ""
uppercase_iam
echo ""
echo -e "____________________________________________"
echo -en '\n'

lowercase_iam(){

low_c=$(aws iam get-account-password-policy | grep RequireLower | awk -F ":" '{print $2}' | sed -e 's/.$//' | sed -e 's/^\s*//')


if aws iam get-account-password-policy | grep "NoSuch" || [ "$low_c" == "false" ]
then
echo -en "${re}WARNING${xx}"
echo ""
echo -en "Lowercase letter force was not setted for IAM password policy!"
echo ""
read -p 'fix? y/n' fix_acc
if [ "$fix_acc" == "y" ]
then
aws iam update-account-password-policy --require-lowercase-characters
fi
else
echo -en "${gr}OK${xx}"
echo ""
echo -en "Lowercase letter force active!"
fi

}

show acc6
echo "Result:"
echo ""
lowercase_iam
echo ""
echo -e "____________________________________________"
echo -en '\n'


trail_control(){

list=$(aws cloudtrail describe-trails | grep trailList | awk -F ":" '{print $2}')
e_list=" []"

trail_n=$(aws cloudtrail describe-trails | grep Name | grep -v S3 | awk -F ":" '{print $2}' | sed -e 's/^\s*//' -e '/^$/d' | sed -e 's/^"//' | sed -e 's/.$//' | sed -e 's/.$//')

region_trail=$(aws cloudtrail describe-trails | egrep '*IsM*' | tr -s [:space:] | awk -F ":" '{print $2}')

f_trail=" true,"

#echo $list
#echo $e_list

fix_trail(){

aws cloudtrail update-trail --name $trail_n --is-multi-region-trail

echo -e "${gr}OK${xx}"

}


if [ "$list" == "$e_list" ]
then
echo -e "${yw}INFORMATION${xx}"
echo -e "Trail not found!"
elif [ "$region_trail" == "$f_trail" ]
then
echo -e "${gr}OK${xx}"
echo "Multi region trail is active."
else
echo -e "${re}WARNING${xx}"
echo "Trail found but multi region is not active."
read -p 'Fix? y/n' fix1
if [ "$fix1" == "y" ]
then
fix_trail
else
echo ""
fi
fi
}

show log1
echo "Result:"
echo ""
trail_control
echo ""
echo -e "____________________________________________"


#fix_trail(){



trail_log_control(){

log_e=$(aws cloudtrail describe-trails | egrep '*LogFile*' | tr -s [:space:] | awk -F ":" '{print $2}' | tr -s \\n)

t_log=" true,"
f_log=" false,"

fix_log_control(){

aws cloudtrail update-trail --name $trail_n --enable-log-file-validation

}
if [ "$log_e" == "$t_log" ]
then
echo -e "${gr}OK${xx}"
echo "Log file validation is enabled."
elif [ "$log_e" == "$f_log" ]
then
echo -e "${yw}INFORMATION${xx}"
echo "Log file validation is disabled."
read -p 'Fix? y/n' fix2
if [ "$fix2" == "y" ]
then
fix_log_control
fi
else
echo -e "${re}WARNING${xx}"
echo "Trail not found."
fi

}

#fix_trail_log(){

show log2
echo "Result:"
echo ""
trail_log_control
echo ""
echo -e "____________________________________________"


s3_bucket_log(){

ct_bucket=$(aws cloudtrail describe-trails --query 'trailList[*].S3BucketName'  | grep [a-Z][0-9] | sed -e 's/^\s*//' -e '/^$/d' | sed -e 's/^"//' | sed -e 's/.$//')

echo -en "S3 Bucket: $ct_bucket"

echo -e ""

s3_all_users=$(aws s3api get-bucket-acl --bucket $ct_bucket --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AllUsers`]')


if [ "$s3_all_users" == "[]"  ]
then
echo -e "${gr}OK${xx}"
echo -e "No permission for everyone!"
else
echo -e "${re}WARNING${xx}"
echo -e "All users are granted!"
fi

ct_bucket_aut=$(aws s3api get-bucket-acl --bucket $ct_bucket --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AuthenticatedUsers`]')

if [ "$ct_bucket_aut" == "[]"  ]
then
echo -e "${gr}OK${xx}"
echo -e "Authentication policy true!"
else
echo -e "${re}WARNING${xx}"
echo -e "Authenticated users are granted!"
fi


s3_bucket_policy=$(aws s3api get-bucket-policy --bucket $ct_bucket)

if [ "$s3_bucket_policy" == "[]"  ]
then
echo -e "${gr}OK${xx}"
echo -e "Bucket policy is fine!"
else
echo -e "${re}WARNING${xx}"
echo -e "Bucket policy should be fix!"
fi

}

show log3
echo "Result:"
echo ""
s3_bucket_log
echo ""
echo -e "____________________________________________"


cloudwatch(){

cdw=$(aws cloudtrail describe-trails | grep Cloud | sed -e 's/^\s*//' -e '/^$/d' | sed -e 's/^"//' | sed -e 's/.$//' | sed -e 's/.$//')

if [ "$cdw" == "[]" ]
then
echo -e "${re}WARNING${xx}"
echo -e "CloudWatch is not enable!"
else
echo -e "${gr}OK${xx}"
echo -e "CloudWatch is enable!"
fi

}

show log4
echo "Result:"
echo ""
cloudwatch
echo ""
echo -e "____________________________________________"


s3_access_log(){

bucket_log=$(aws s3api get-bucket-logging --bucket $ct_bucket)

if [ "$bucket_log" == "" ]
then
echo -e "${re}WARNING${xx}"
echo -e "S3 Bucket logging is disabled."
else
echo -e "${gr}OK${xx}"
echo -e "S3 Bucket logging is enabled."
fi

}

show log6
echo "Result:"
echo ""
s3_access_log
echo ""
echo -e "____________________________________________"

cmk_kms(){

kms_e=$(aws cloudtrail describe-trails | grep Kms)

if [ "$kms_e" == "" ]
then
echo -e "${re}WARNING${xx}"
echo "SSE KMS is disabled!"
else
echo -e "${gr}OK${xx}"
echo "SSE KMS is enabled!"
fi

}

show log7
echo "Result:"
echo ""
cmk_kms
echo ""
echo -e "____________________________________________"

cmk(){

key_id=$(aws kms list-keys | egrep KeyId | awk -F ":" '{print $2}' | sed -e 's/^\s*//' -e '/^$/d' | sed -e 's/^"//' | sed -e 's/.$//')

kms_l=$(aws kms list-keys)

keys_e=" []"

fix_key_rotation(){

aws kms enable-key-rotation --key-id $key_id

}

if [ "$kms_l" == "$keys_e" ]
then
echo -e "${re}WARNING${xx}"
echo "Master Key not found!"
rotation_e=$(aws kms get-key-rotation-status --key-id $key_id | egrep KeyRot | awk -F ":" '{print $2}' | sed -e 's/^\s*//' -e '/^$/d')
elif [ "$rotation_s" == "false" ]
then
echo -e "${yw}INFORMATION${xx}"
echo "Key Rotation is disabled!"
read -p "Fix it? y/n" fix3
if [ "$fix3" == "y" ]
then
fix_key_rotation
fi
else
echo -e "${gr}OK${xx}"
echo "Key rotation is enabled!"
fi

}

show log8
echo "Result:"
echo ""
cmk
echo ""
echo -e "____________________________________________"
