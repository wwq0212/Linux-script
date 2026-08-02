#！/bin/bash
#生成密钥函数
Make_Key(){
expect << eof
spawn ssh-keygen
expect "id_rsa):"
send "\r"
expect {
   "Overwrite" {
   send "y\r"
   expect "passphrase):"
   send "\r"
   expect "again:"
   send "\r"
   }  

   "passphrase):" {
   send "\r"
   expect "again:"
   send "\r"
 }
}
expect eof
eof
}

#备份
time=$(date +"%Y:%m:%d:%T")
mysqldump -uroot -p'111111' --master-data=2 --single-transaction -B test1 >full_${time}.sql

#加密
md5sum full_${time}.sql >full_${time}.flag

#建立连接
 ssh="/root/.ssh"
 if [ -d ${ssh} ];
 then
  echo "准备连接"
 else
  echo "首次连接，生成密钥"
  Make_Key
 fi


 file=($(ls /root/.ssh/))
 file_num=${#file[@]}
 if [ ${file_num} -eq 0 ];
  then
  echo "密钥丢失,生成密钥"
  Make_Key
 exit
 fi


 is_exist=0
 is_exist1=0
 for x in ${file[@]};
  do
   if [[ $x == "id_rsa" ]] || [[ $x == "id_rsa.pub" ]];
   then
    is_exist1=1
   else
    is_exist1=0
   fi
  let is_exist=${is_exist1}+${is_exist}
 done
 if [ ${is_exist} -ne 2 ];
 then
  echo "密钥丢失,生成密钥"
  Make_Key
 fi

  expect << eof
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.40.101
expect {
         "(yes/no)?" {
         send "yes\r"
         expect "password"
         send "1\r"
     }
     "password" {
         send "1\r"
     }
     "WARNING" {
         exit 0
     }
     "No route to host" {
         exit 30
     }
     "password" {
         send "1\r"
     expect "please try again."
         send "1\r"
     expect "please try again."
         send "1\r"
     expect "(publickey,password)."
         exit 20
     }
     "Connection refused"{
         exit 40
     }
     timeout {
         exit 10
     }

}
expect eof
eof
ssh root@192.168.40.101 "exit"
if [ $? -ne 0 ];
then
echo "连接失败，请检查网络连接"
exit 10
else
 echo "准备推送备份服务器"
fi
#推送备份服务器
rsync -av "./full_${time}.sql" "./full_${time}.flag" root@192.168.40.101:/test/

#验证是否被篡改
ssh root@192.168.40.101 "cd /test/;md5sum -c full_${time}.flag"

if [ $? -eq 0 ];
then 
 echo "备份成功"
else
 echo "备份失败，备份文件被修改"
exit 20
fi


 

