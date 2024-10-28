/*
 * Additional methods needed for the OpportunityTriggerHandler class
 * 
 * @author Patrick Sees
*/


public with sharing class OpportunityUtilities {

    public static Boolean isStageChangeHandled = false;

    public static Boolean  isPrimaryContactChangedAlready = false;


    public static void defaultNewCustomers(List<Opportunity> oppys){

        for (Opportunity opp : oppys) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }        
        }        
    }            

    public static void preventClosedOppyDelete(List<Opportunity> oppys){

    // Prevent deletion of closed Opportunities

        for (Opportunity oldOpp : oppys){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void opportunityMustBeFiveThousand(List<Opportunity> oppys){

    // When an opportunity is updated validate that the amount is greater than 5000.

        for (Opportunity opp : oppys) {
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }


    public static void cantDeleteClosedWonBanking(List<Opportunity> oppys){
        
    // When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
        List<Id> accIdList = new List<Id>();
        for (Opportunity oldOpp : oppys) {
            accIdList.add(oldOpp.AccountId);
        }

        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN:accIdList]);

        for (Opportunity opp : oppys) {
            if (opp.Account.Industry == 'Banking' && opp.StageName == 'Closed Won')  {
                opp.addError('Cannot delete closed opportunity');
            }
        }
    }

    // Set default Type for new Opportunities
    public static void setNewOppyAsNewCustomer(List<Opportunity> oppys){

        for (Opportunity opp : oppys) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }

    }


    // Create a new Task for newly inserted Opportunities
    public static void newOppyGetsTask(List<Opportunity> oppys){

        //Creating a list to hold the tasks
        List<Task> tasks = new List<Task>();

        for (Opportunity opp : oppys) {
            Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);

                //adding each task to the above list
                tasks.add(tsk);
            }
        insert tasks;

    }

    // Append Stage changes in Opportunity Description
    public static void appendStageChangeInOppyDescription(List<Opportunity> oppys) {

        // Check if the stage change has already been handled in this transaction
        if (OpportunityUtilities.isStageChangeHandled) {
            return; // Exit if already handled to prevent recursion
        }
    
        // Set the flag to true to prevent further updates in the same transaction
        OpportunityUtilities.isStageChangeHandled = true;
    
        system.debug(oppys);

        for (Opportunity opp : oppys) {
            if (opp.StageName != null) {
                opp.Description += 'Stage Change:' + opp.StageName;
            }
        }
    }


    // Trigger should only fire on update.

    // When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'
    public static void updatePrimaryContact(List<Opportunity> oppys){

        List<Id> accountIds = new List<Id>();

            for (Opportunity opp : oppys) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }

            Map<Id, Contact> accountCEOs = new Map<Id, Contact>([SELECT Id, AccountId, Title FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO']);

            Map<Id, Contact> accountIdContactMap = new Map<Id, Contact>();

                for (Contact con : accountCEOs.values()) {
                    accountIdContactMap.put(con.AccountId, con);
                }

                for(Opportunity opp : oppys){
                    if(opp.Primary_Contact__c == null && accountIdContactMap.containsKey(opp.AccountId)){
                        opp.Primary_Contact__c = accountIdContactMap.get(opp.AccountId).Id;
                    }
                }
    }    


    // Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities 
    // Only updates the Opportunities that don't already have a primary contact   

    public static void assignPrimaryContact(Map<Id, Opportunity> oppNewMap) {

        // Check if the stage change has already been handled in this transaction
        if (OpportunityUtilities.isPrimaryContactChangedAlready) {
            return; // Exit if already handled to prevent recursion
        }
    
        // Set the flag to true to prevent further updates in the same transaction
        OpportunityUtilities.isPrimaryContactChangedAlready = true;
    

        List<Opportunity> noPrimaryContact = new List<Opportunity>([SELECT Id, AccountId, Primary_Contact__c FROM Opportunity WHERE Primary_Contact__c = null]);
        
        system.debug(noPrimaryContact + '+++++++++++++');

        List<Id> accountIds = new List<Id>();

            for (Opportunity opp : noPrimaryContact) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }

       
        Map<Id, Contact> accountVpSales = new Map<Id, Contact>([SELECT Id, AccountId, Title FROM Contact WHERE AccountId IN :accountIds AND Title = 'VP Sales']);
        
        Map<Id, Contact> accountIdContactMap = new Map<Id, Contact>();

            for (Contact con : accountVpSales.values()) {
                accountIdContactMap.put(con.AccountId, con);
            }

            for(Opportunity opp : noPrimaryContact){
                if(opp.Primary_Contact__c == null && accountIdContactMap.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdContactMap.get(opp.AccountId).Id;
                }
            }
        update noPrimaryContact;

    }


    // - Sends an email notification to the owner of the Opportunity when it gets deleted.
    // - Uses Salesforce's Messaging.SingleEmailMessage to send the email.

    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Set<Id> ownerIds = new Set<Id>();
            for (Opportunity opp: opps) {
                ownerIds.add(opp.OwnerId);
            }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);
                

            for (Opportunity opp : opps){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] {userMap.get(opp.OwnerId).Email});
                mail.setSubject('Opportunity Deleted : ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
                mails.add(mail);
            }        
            
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e){
                System.debug('Exception: ' + e.getMessage());
            }
        }

/*
}
        // Send email notifications when an Opportunity is deleted 
        else if (Trigger.isDelete){
            notifyOwnersOpportunityDeleted(Trigger.old);
        } 
        // Assign the primary contact to undeleted Opportunities
        else if (Trigger.isUndelete){
            assignPrimaryContact(Trigger.newMap);
        }
    }

 
    
    private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {[SELECT Id, Email FROM User WHERE Id = :opp.OwnerId].Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }
        


    */

}