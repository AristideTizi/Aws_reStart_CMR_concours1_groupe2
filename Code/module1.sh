#!/bin/bash

function find_user {
	grep -i $1 /etc/passwd > tempUser.txt
	if [ -s tempUser.txt ]
	then
		echo "[L'utilisateur \"$1\" existe]"
	else
		echo "-----------------------------------------"
		echo "[L'utilisateur \"$1\" n'existe pas]"
		echo "-----------------------------------------"
		touch tempCompte.txt
	fi
}

function list_user {
	i=0
	while IFS="" read -r LINE || [ -n "${LINE}" ];
	do
		echo "--------------------------------------"
		echo "Resultat " $(($i+1))
		echo "${LINE}" > tempCompte.txt
		idUser=`cut -d ':' -f 1 tempCompte.txt`
		echo "Identifiant du compte: " $idUser
		user_result[$(($i+1))]=$idUser
		nomUser=`cut -d ':' -f 5 tempCompte.txt`
		echo "Details sur l'utilisateur: " $nomUser
		((i++))
	done < tempUser.txt
}
echo "---------------------------------------------"
echo "|BIENVENUE SUR LE PROGRAMME D'ADMINISTRATION|"
echo "---------------------------------------------"
echo "Quelle opération souhaitez-vous effectuer?"
echo "1- Verifier un utilisateur"
echo "2- Ajouter un utilisateur"
echo "3- Activer/Desactiver un compte d'utilisateur"
echo "4- Supprimer un utilisateur"
# Archiver automatiquement le dossier de l'user supprimé
# Supprimer l'archiver 30 jours après la suppression de l'user
echo "--------------------------------------------------"
echo -n "Votre choix : "
read choix

if (($choix==1))

then
	echo "Entrer le nom du compte d'utilisateur que vous souhaitez verifier"
	echo "-----------------------------------------------------------------"
	read nomCompte
	find_user "$nomCompte"
	
	list_user 

	rm tempCompte.txt
	rm tempUser.txt

elif (($choix==2))
then
	echo "-----------------------------------------------------------------"
	echo "AJOUTER UN UTILISATEUR"
	echo "1- Ajouter manuellement un utilisateur"
	echo "2- Ajouter dynamiquement un utilisateur"
	echo -n "Votre choix : "
	read choix

	if (($choix==1))
	then
		echo "---------------------------------------------------------------"
		echo "AJOUTER MANAUELLEMENT UN UTILISATEUR"
		echo -n "Entrez l'identifiant de l'utilisateur: "
		read identifiantUser
#Verifier que l'utilisateur n'existe pas déja
		echo -n "Entrez le prénom de l'utilisateur: "
		read prenomUser
		echo -n "Entrez le nom de l'utilisateur: "
		read nomUser
		echo -n "Entrez la date d'expiration du compte (AAAA-MM-JJ): "
		read dateExpiration
		until [[ $dateExpiration =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && date -d "$dateExpiration" >/dev/null 2>&1 && [[ $(date -d "$dateExpiration" +"%s") -ge $(date +"%s") ]]
		do
			echo "Format incorrect et/ou date déjà passée. Veuillez entrer une date à venir suivant le format AAAA-MM-JJ : "
			read dateExpiration
		done
		echo -n "Entrez un commentaire: "
		read commentaire
		passwordUser=`pwgen -s 10 1`
	
		sudo useradd -m $identifiantUser -p $(openssl passwd "$passwordUser") -e "$dateExpiration" -c "$prenomUser,$nomUser,$commentaire"
		sudo passwd -e $identifiantUser	
		echo "--L'utilisateur $identifiantUser a été créé--"
		echo "$identifiantUser:$passwordUser" >> passwordsGenerated.txt
		echo "--Le mot de passe temporaire de l'utilisateur est stocké dans le fichier passwordsGenerated.txt--"
		echo "--Le mot de passe doit être changé à la prochaine connexion--"
		echo ""
		echo "A quel(s) groupe(s) voulez-vous que l'utilisateur appartienne ? (Pour choisir plusieurs groupes, respectez le format \"groupe1,groupe2,groupe3\" ou bien tapez sur ENTRER si aucun groupe) :  "
		read groupeUser
#Vérifier que le format est correct et que les groupes existent
		sudo usermod -aG "$groupeUser" $identifiantUser
		echo "--L'utilisateur a été ajouté dans le(s) groupe(s) $groupeUser--"
		

	elif (($choix==2))
	then
		echo "---------------------------------------------------------------"
		echo "AJOUTER DYNAMIQUEMENT DES UTILISATEURS"
		echo "Entrez le chemin du fichier:"
		read fichierCsv
		while IFS="" read -r LINE || [ -n "${LINE}" ]
		do
			echo "${LINE}" > tempoUser.txt
			identifiant=`cut -d ';' -f 1 tempoUser.txt`
			firsName=`cut -d ';' -f 2 tempoUser.txt`
			lastName=`cut -d ';' -f 3 tempoUser.txt`
			comment=`cut -d ';' -f 4 tempoUser.txt`
			expirationDate=`cut -d ';' -f 5 tempoUser.txt`
			group=`cut -d ';' -f 6 tempoUser.txt`

			passwordUser=`pwgen -s 10 1`

			sudo useradd -m $identifiant -p $(openssl passwd "$passwordUser") -c "$comment" -e "$expirationDate"
			echo "$identifiant:$passwordUser" >> passwordsGenerated.txt
			sudo passwd -e $identifiant
			sudo usermod -aG "$group" $identifiant
			echo "Utilisateur [$identifiant] bien créé"
		done < $fichierCsv
		rm tempoUser.txt
		echo "--Opération terminé--"
	else
		echo "Choix non valide"
	fi

elif (($choix==3))
then
	echo "---------------------------------------------------------------"
	echo "ACTIVER/DESACTIVER UN UTILISATEUR"
	echo -n "Veuillez entrer le nom de l'utilisateur: "
	read nomCompte
	grep -i $nomCompte /etc/passwd > tempUser.txt
	if [ -s tempUser.txt ]
	then
		declare -a user_result
		list_user
		echo "--------------------------------------"
		echo -n "selectionner un resultat: "
		read choixResult
		echo "----------------------------------------------------------------------"
		choixUser=${user_result[$choixResult]}
		echo "Vous avez choisi l'utilisateur dont l'identifiant est [$choixUser]"

		echo "1- Activer l'utilisateur"
		echo "2- Desactiver l'utilisateur"
		echo -n "Votre choix : "
		read choix
		if (($choix==1))
		then
			sudo chage -E -1 $choixUser
			echo "--L'utilisateur a bien été activé--"
		elif (($choix==2))
		then
			sudo chage -E 0 $choixUser
			echo "--L'utilisateur a bien été désactivé--"
		else
			echo "Choix non valide"
		fi
	else
		echo "-----------------------------------------"
		echo "[L'utilisateur \"$nomCompte\" n'existe pas]"
		echo "-----------------------------------------"
	fi

	rm tempCompte.txt
	rm tempUser.txt
elif (($choix==4))
then
	echo "SUPPRIMER UN UTILISATEUR"
	echo -n "Veuillez entrer le nom de l'utilisateur: "
	read nomCompte
	grep -i $nomCompte /etc/passwd > tempUser.txt
	if [ -s tempUser.txt ]
	then
		declare -a user_result
		list_user
		echo "--------------------------------------"
		echo -n "selectionner un resultat: "
		read choixResult
		echo "----------------------------------------------------------------------"
		choixUser=${user_result[$choixResult]}
		echo "Vous avez choisi l'utilisateur dont l'identifiant est [$choixUser]"

		echo "1- Confirmer"
		echo "2- Annuler"
		echo -n "Votre choix : "
		read choix
		if (($choix==1))
		then
			nomArchive=$choixUser.tar.gz
			sudo tar -czf $nomArchive -P /home/$choixUser
			sudo mv $nomArchive /home/ari/projectConcours1/usersArchive
			echo "--Le repertoire de l'utilisateur a bien été archivé--"
			echo "rm ./usersArchive/$nomArchive" | at now +30 days
			echo "--L'archive du repertoire de l'utilisateur sera supprimé dans 30 jours--"
			sudo userdel -r $choixUser
			echo "--L'utilisateur [$choixUser] a bien été supprimé--"
		elif (($choix==2))
		then
			echo "--Operation annulée--"
		else
			echo "Choix non valide"
		fi
	else
		echo "-------------------------------------------"
		echo "[L'utilisateur \"$nomCompte\" n'existe pas]"
		echo "-------------------------------------------"
	fi

	rm tempCompte.txt
	rm tempUser.txt
else
	echo "Choix non valide, veuillez recommencer s'il vous plait"
	./module1.sh
fi

echo "-------------------"
echo "Fin de l'opération"
echo "-------------------"
echo "voulez-vous effectuer une autre opération?"
echo "1: OUI     autre: NON"
echo -n "Votre choix: "
read choix
if (($choix=="1"))
then
	./module1.sh
else
	echo "-----------------"
	echo "FIN DU PROGRAMME"
	echo "-----------------"
	exit
fi