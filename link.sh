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



ssh="/root/.ssh"
if [ -d ${ssh} ];
then
 echo "the file exit "
else
 echo "生成密钥"
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


