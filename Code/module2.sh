#!/bin/bash

#Script permettant d'archiver les dossiers personnels des utilisateurs et les envoyer sur un serveur distant

for repos in /home/ari/projectConcours1/reposHome/*
do
	nomArchive=$repos.tar.gz
	tar -czf $nomArchive -P $repos
	scp $nomArchive ari@127.0.0.1:/home/ari/sharedFolders
	echo "[Sauvegardé]" $nomArchive 
	rm $nomArchive
done
echo "[Sauvegarde des repertoires personnels terminée]"
