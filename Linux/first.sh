# #!/usr/bin/env bash
#
# # echo Command
# echo "Hello World!"
#
# # Variables
# Name="Vaish"
# echo "My name is ${Name}"
#
# # User Inputs
# read -p "Enter your name:" Name1
# echo "Hello ${Name1} , Nice to meet you!!"
#
# # if-Elif-Else-fi
# if [ ${Name} == "Viaan" ]
# then
#   echo "Hello You have passed if condition"
# elif [[ ${Name1} == "Viaan" ]]; then
#
#   echo "Hello You have passed elif condition"
# else
#   echo "Hello You have passed else condition"
#
# fi
#
# # -eq -ne -ge -gt -le -lt
# Num1=13
# Num2=4
# if [ ${Num1} -eq ${Num2} ]
#
# then
#   echo "Numbers are not equal"
# elif [ ${Num1} -le ${Num2} ]
# then
#   echo "Num1 is less than Num2"
# else
#   echo "Num1 is greater than Num2"
# fi

# # Switch case
# read -p "Are you 21 ? Enter Yes / No ::" Answer
# case ${Answer} in
#   [yY] | [Yy][Ee][Ss])
#   echo "You can dance"
#   ;;
#
#   [Nn] | [Nn][Oo])
#   echo "You can't dance"
#   ;;
#
#   *)
#   echo "Please Enter yes or no"
#   ;;
# esac
