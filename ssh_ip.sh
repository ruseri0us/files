#/bin/bash
echo "SSH to Remote Host by segmenting --- #Permission Denied --- #Connection Error --- #Connection Success"
for name in $(cat ip.txt);do
echo 'Check for IP:'$name
sresult=$(sshpass -p 'toor' ssh -o StrictHostKeyChecking=no NumberOfPasswordPrompts=1 root@$name whoami 2>&1)
echo $sresult >> perm_sh_log.txt
wresult=$(echo $sresult | cut -d " " -f1)
eresult="Permission"
cresult=$(echo $sresult | grep -o connect)
aresult="connect"
if [[ "$wresult" == "$eresult" ]]; then
	echo $name - $sresult >> perm_sh_log.txt
	echo $name >> denied_ip.txt
		echo '--------------------------------------------------------------------------------------------' >> perm_sh_log.txt
elif [[ "$cresult" == "$aresult" ]]; then
	echo $name - $sresult >> perm_sh_log.txt
	echo $name >> conn_error_ip.txt
        echo '--------------------------------------------------------------------------------------------' >> perm_sh_log.txt
else
	echo $name - Connection Success >> perm_sh_log.txt
	echo $name >> connected_ip.txt
	sshpass -p 'toor' ssh -o StrictHostKeyChecking=no NumberOfPasswordPrompts=1 root@$name  hostname >> hostname.txt
        echo '--------------------------------------------------------------------------------------------' >> perm_sh_log.txt
fi
sleep 5s
done
