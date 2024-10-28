public with sharing class OpportunityTriggerHandler extends TriggerHandler{

        public override void beforeInsert(){

            OpportunityUtilities.defaultNewCustomers(Trigger.new);

            OpportunityUtilities.setNewOppyAsNewCustomer(Trigger.new);
        }
        
        public override void afterInsert(){

            OpportunityUtilities.newOppyGetsTask(Trigger.new);

        }
    
        public override void beforeDelete(){

            OpportunityUtilities.preventClosedOppyDelete(Trigger.old);

            // When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
            OpportunityUtilities.cantDeleteClosedWonBanking(Trigger.old);
        }

        public override void beforeUpdate(){
    
            OpportunityUtilities.opportunityMustBeFiveThousand(Trigger.new);
            OpportunityUtilities.appendStageChangeInOppyDescription(Trigger.new);
            OpportunityUtilities.updatePrimaryContact(Trigger.new);

        }    

        @TestVisible
        public override void afterUndelete(){

            OpportunityUtilities.assignPrimaryContact((Map<Id, Opportunity>) Trigger.newMap);
            
        }

        
        public override void afterDelete(){
        
            OpportunityUtilities.notifyOwnersOpportunityDeleted(Trigger.old);
        }
}
/*






                // Send email notifications when an Opportunity is deleted 
                else if (Trigger.isDelete){
                    notifyOwnersOpportunityDeleted(Trigger.old);
                } 
                // Assign the primary contact to undeleted Opportunities
                else if (Trigger.isUndelete){
                    assignPrimaryContact(Trigger.newMap);
                }
            }
        
            /*
            notifyOwnersOpportunityDeleted:
            - Sends an email notification to the owner of the Opportunity when it gets deleted.
            - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
            */

   /*         
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
        
            /*
            assignPrimaryContact:
            - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
            - Only updates the Opportunities that don't already have a primary contact.
            
            private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
                for (Opportunity opp : oppNewMap.values()){            
                    Contact primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId = :opp.AccountId LIMIT 1];
                    if (opp.Primary_Contact__c == null){
                        Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                        oppToUpdate.Primary_Contact__c = primaryContact.Id;
                        oppMap.put(opp.Id, oppToUpdate);
                    }
                }
                update oppMap.values();
            }
        }



    }




    /*
    * Opportunity Trigger
    * When an opportunity is updated validate that the amount is greater than 5000.
    * Trigger should only fire on update.
    
    if (Trigger.isUpdate && Trigger.isBefore){
        for(Opportunity opp : Trigger.new){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    /*
    * Opportunity Trigger
    * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
    * Trigger should only fire on delete.
    
    if (Trigger.isDelete){
        //Account related to the opportunities 
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :Trigger.old)]);
        for(Opportunity opp : Trigger.old){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete a closed won opportunity for a banking account');
                }
            }
        }
    }

    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * Trigger should only fire on update.
    
    if (Trigger.isUpdate && Trigger.isBefore){
        //Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : Trigger.new){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : Trigger.new){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
            */