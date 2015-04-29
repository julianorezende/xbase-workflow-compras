#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "TOPCONN.CH"   
#INCLUDE "Ap5Mail.ch"

*------------------------------------------------------------------------------------------------------------------------------------*
* Fonte      * M110STTS * Autor  * CONSULTORIA ON LINE   * Benedic, Domine Deus, in hac societate quae facit.	Data *  16/04/2014					  *
*------------------------------------------------------------------------------------------------------------------------------------*
* Descricão  * Ponto de entrada para gravar campo memo.																								  *
*------------------------------------------------------------------------------------------------------------------------------------*
* Uso        * 	Renovagro	- Modulo Compras 																										 *
*------------------------------------------------------------------------------------------------------------------------------------*
* Consultor  * Juliano Rezende Ribeiro 																												  *
*------------------------------------------------------------------------------------------------------------------------------------*

User Function M110STTS()

Local aArea     := GetArea()
          
//MSMM(SC1->C1_CODOBS,,,aCols[n][aScan(aHeader,{|x| UPPER(AllTrim(x[2]))=="C1_OBSMEMO" })],1,,,"SC1","C1_CODOBS")    

If INCLUI .OR. ALTERA //Verifica se e Inclusao ou Alteracao da Solicitacao   
//    MSMM(SC1->C1_CODOBS,,,aCols[n][aScan(aHeader,{|x| UPPER(AllTrim(x[2]))=="C1_OBSMEMO" })],1,,,"SC1","C1_CODOBS")    
	MsgRun("Enviando Workflow para Aprovador da Solicitação, Aguarde...","",{|| CursorWait(), U_COMRD001() ,CursorArrow()})    
//	RecLock("SC1",.F.)
//	SC1->C1_APROV:="B"
//	MsUnlock()     


// inicio             
cNumSC := SC1->C1_NUM
cQuery := " UPDATE "+RETSQLNAME("SC1")                                
cQuery += " SET C1_APROV = 'B' "
cQuery += " WHERE C1_NUM = '"+cNumSC+"'  AND C1_FILIAL = '" + XFILIAL("SC1") + "' AND D_E_L_E_T_ = ' ' "

TcSqlExec(cQuery)
//TCREFRESH(RetSqlName("SC1"))


//fim
EndIf

RestArea(aArea)

Return .T.
