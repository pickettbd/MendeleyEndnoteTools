#! /bin/bash

# ----------------  COLOR MANAGEMENT  ------------------------------------ ||
RED="\e[0;31m"
LRED="\e[1;31m"
GREEN="\e[0;32m"
LGREEN="\e[1;32m"
BLUE="\e[0;34m"
LBLUE="\e[1;34m"
CYAN="\e[0;36m"
LCYAN="\e[1;36m"
PURPLE="\e[0;35m"
LPURPLE="\e[1;35m"
YELLOW="\e[0;33m"
LYELLOW="\e[1;33m"
NC="\e[0m" # No color

# ----------------  FUNCTIONS   ------------------------------------------ ||
initial()
{
	REMOVE_PDFS=0
	PDF_DIR="${HOME}/Desktop/My Collection.Data"
	XML_FILE="${HOME}/Desktop/My Collection.xml"
	TEMP_FILE=/tmp/removePDFsFromMendeleyEndnoteExport.${$}.${RANDOM}
}

handle_args()
{
	local USAGE
	local EXAMPLE
	USAGE="  USAGE: $0.sh [-x file.xml] [-p [-d pdf_directory]]"
	EXAMPLE="EXAMPLE: $0.sh -x /path/to/some/collection.xml -p -d /path/to/some/pdf_directory"

	local DASH_D
	local DASH_X
	DASH_D=0
	DASH_X=0
	OPTERR=1 # prevent annoying getopts errors

	while getopts ":d:hpx:" opt
	do
		case ${opt} in
			d)
				PDF_DIR="${OPTARG}"
				DASH_D=1

				if [ -z "$PDF_DIR" ]
				then
					printf "\n\t${RED}%s\n\n${NC}" \
						"ERROR: \`-${opt}' requires a non-empty argument." \
						1>&2
					exit 1
				fi
				;;
			h)
				printf "\n${USAGE}\n${EXAMPLE}\n\n"
				exit 0
				;;
			p)
				REMOVE_PDFS=1
				;;
			x)
				XML_FILE="${OPTARG}"
				DASH_X=1

				if [ -z "$XML_FILE" ]
				then
					printf "\n\t${RED}%s\n\n${NC}" \
						"ERROR: \`-${opt}' requires a non-empty argument." \
						1>&2
					exit 1
				fi
				;;
			\?)
				printf "\n${RED}ERROR: Invalid option: -${OPTARG}${NC}\n\n" 1>&2
				exit 1
				;;
			:)
				printf "\n${RED}ERROR: Option -${OPTARG} requires an argument.${NC}\n\n" 1>&2
				exit 1
				;;
		esac
	done

	if ((${REMOVE_PDFS}))
	then
		if [ ! -e "${PDF_DIR}" ] || [ ! -d "${PDF_DIR}" ]
		then
			printf "\n\t${RED}%s\n\n${NC}" \
				"ERROR: \`${PDF_DIR}' did not exist or was not a directory." \
				1>&2
			exit 1
		fi
	else
		if ((${DASH_D}))
		then
			printf "\n\t${RED}%s\n\n${NC}" \
				"ERROR: You must supply \`-p' to remove PDFs (and thus use \`-d')." \
				1>&2
			exit 1
		fi
	fi

	if [ ! -e "${XML_FILE}" ]
	then
		printf "\n\t${RED}%s\n\n${NC}" \
			"ERROR: \`${XML_FILE}' did not exist." \
			1>&2
		exit 1
	fi

	shift ${OPTIND}

	if [ $# -lt 0 ]
	then
		printf "\n\t${RED}%s\n\n${NC}" \
			"ERROR: You cannot supply any positional parameters." \
			1>&2
		exit 1
	fi
}

cleanup()
{
	rm -f /tmp/removePDFsFromMendeleyEndnoteExport.* &> /dev/null
}

control_c()
{
	cleanup
	exit 1
}

# ----------------  MAIN SCRIPT ------------------------------------------ ||
trap control_c SIGINT SIGTERM
initial
handle_args "$@"

# remove pdfs (if desired)
if ((${REMOVE_PDFS}))
then
	rm -rd "${PDF_DIR}"
fi

# remove links to pdfs in xml file
sed -E 's,<pdf-urls>(<url>internal-pdf:[^<]+</url>)+</pdf-urls>,,g' "${XML_FILE}" > ${TEMP_FILE}
mv ${TEMP_FILE} "${XML_FILE}"

cleanup

exit 0
