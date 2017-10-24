#!/bin/sh
#ユーザー設定領域 ここから
#ETH_DEV ipv6グローバルアドレスが振られるインターフェイス
#REMOTE  DSliteの接続先
#NTT東日本エリア 2404:8e00::feed:100 2404:8e00::feed:101
#NTT西日本エリア 2404:8e01::feed:100 2404:8e01::feed:101
#必ず''で囲む
ETH_DEV='eth0'
REMOTE='2404:8e00::feed:101'
PING_IP='8.8.8.8'
#ユーザー設定領域　ここまで

#グローバルなIPv6をLOCALに代入
LOCAL=`ip addr show $ETH_DEV |grep 'inet6'  | grep 'global' |awk '{print $2}'  | awk -F/ '{print $1}'`
#ネットワークが起動しても、ipv6のアドレスが（割当が遅くて）ない場合があるので、取得し続ける
while [ -z $LOCAL ]
do
	sleep 0.5s
	LOCAL=`ip addr show $ETH_DEV |grep 'inet6'  | grep 'global' |awk '{print $2}'  | awk -F/ '{print $1}'`	
done
#echo $LOCAL
#カーネルモジュールの有効化
modprobe ip6_tunnel
#トンネル作成
ip -6 tunnel add dslite mode ip4ip6 remote $REMOTE local $LOCAL dev $ETH_DEV
#トンネルの起動
ip link set dev dslite up
#デフォルトゲートウェイの削除
route delete default
#作成したトンネルをデフォルトゲートウェイに指定
route add default dev dslite
#ipv4のフォワーディングを有効
sysctl -w net.ipv4.ip_forward=1

while true
do
	sleep 5s
	ping $PING_IP -c 5  >> /dev/null
	
	if [ $? -eq 1 ] ;
	then
		LOCAL=''
		while [ -z $LOCAL ]
		do
			sleep 0.5s
			LOCAL=`ip addr show $ETH_DEV |grep 'inet6'  | grep 'global' |awk '{print $2}'  | awk -F/ '{print $1}'`
		done
		route delete default
		route add default dev $ETH_DEV
		ip link set dev dslite down
		ip tunnel del dslite
		ip -6 tunnel add dslite mode ip4ip6 remote $REMOTE local $LOCAL dev $ETH_DEV
		ip link set dev dslite up
		route delete default
		route add default dev dslite
		echo "ds-lite reconnected"
	fi
done

	
