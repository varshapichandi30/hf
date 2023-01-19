NUM=1
NODE_CERT=$(ls ./build/crypto-config/ord${NUM}_MSP/msp/signcerts/*.pem)
kubectl create secret generic -n orderers hlf--ord${NUM}-idcert --from-file=cert.pem=${NODE_CERT}

NODE_KEY=$(ls ./build/crypto-config/ord${NUM}_MSP/msp/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord${NUM}-idkey --from-file=key.pem=${NODE_KEY}

ORG_TLS=$(ls ./build/crypto-config/OrdererMSP/tlscacerts/*.pem)
kubectl create secret generic -n orderers hlf--ord-tlsrootcert --from-file=key.pem=${ORG_TLS}

ORD_TLS_CERT=$(ls ./build/crypto-config/ord${NUM}_MSP/tls/signcerts/*.pem)
ORD_TLS_KEY=$(ls ./build/crypto-config/ord${NUM}_MSP/tls/keystore/*_sk)
kubectl create secret generic -n orderers hlf--ord${NUM}-tls --from-file=server.crt=${ORD_TLS_CERT} --from-file=server.key=${ORD_TLS_KEY}