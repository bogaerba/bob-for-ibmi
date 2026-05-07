I want to create a project that prepares an IBM i LPAR for use with IBM Bob. I will need to create a new LPAR, configure it with the necessary software, and set up the environment for use with Bob. I will also need to ensure that the LPAR is properly secured and that the necessary security measures are in place. Additionally, I will need to create a user profile and set up access controls to ensure that only authorized users can access the LPAR. Finally, I will need to test the LPAR to ensure that it is functioning properly and that all necessary components are in place.
The LPAR needs to have the following specifications:
* needs to have https://github.com/IBM/ibmi-company_system cloned

* needs to have these packages installed: git tn5250 service-commander mapepire-server rsync ibmichroot nano tobi
* ~/.bash_profile needs to have:
## PS1: Shell prompt format
PS1="\e[1;34m[\u@\h \W]\$ \e[m"
export PS1
## PATH: All PASE binaries are in /QOpenSys/pkgs/bin
PATH=/QOpenSys/pkgs/bin:$PATH
export PATH
## LANG: some tools (for example: tmux) need UTF-8 charset
LANG=EN_US.UTF-8
export LANG

* in the 'Db2 for i' extension: Examples → Miscellaneous → Call Create SQL Sample with Schema
run this SQL command: CALL QSYS.CREATE_SQL_SAMPLE('SAMCO');
* build the ibmi-company_system project using '/QOpenSys/pkgs/bin/makei build'
