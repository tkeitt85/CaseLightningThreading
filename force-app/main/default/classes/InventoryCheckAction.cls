/* Anonymous Apex boiler plate
List<InventoryCheckAction.Requests> requestList = new List<InventoryCheckAction.Requests>();
Set<Id> quoteIdList = new Set<Id>{'a2Q4P000002CD75UAG','a0x4P00000EUKu8QAH','a0x7A000001pZSrQAM'};

for(Id q : quoteIdList){
    InventoryCheckAction.Requests request = new InventoryCheckAction.Requests();
    request.quoteIds = new List<Id>{q};
    requestList.add(request);
}

System.debug('quoteIds list:::' + requestList);

List<InventoryCheckAction.Results> resultsList = InventoryCheckAction.execute(requestList);

for(InventoryCheckAction.Results result : resultsList){
    System.debug('Inventory Capacity: ' + result.icList);
}
*/
public class InventoryCheckAction
{
    public static Map<ID, InventoryWrapperClass.qDetails> mProductToDetails = new map <ID, InventoryWrapperClass.qDetails>();
    public static Map<String, InventoryWrapperClass.qDetails> uniqueKeyToDetails = new Map<String, InventoryWrapperClass.qDetails>();
    public static Map<String, Date> uniqueKeyToDwStartDate = new Map<String, Date>();
    public static Set<String> uniqueKeys = new set<String>();  
    public static Set<String> uniqueKeyDone = new Set<String>();
    public static Set<String> uniqueKeyDwDone = new Set<String>();
    public static Set<String> uniqueKeyCalcCap = new Set<String>();
    public static Date currentDW = InventoryUtilsClass.generateStartDW(system.today());
    public static Map<String, InventoryWrapperClass.hgDetails> uniqueKeyToHgDetails = new map<String, InventoryWrapperClass.hgDetails>();
    public static List<InventoryCapacityClassDescriptor> icList = new List<InventoryCapacityClassDescriptor>();
    public static Boolean qFail;
    public static List<Results> results = new List<Results>();
    public static Results result = new results();
    public static Integer countRequests = 0;


    @InvocableMethod(   label='Check Inventory Action'
                        iconName='slds:standard:product'
                        description='Checks the Inventory levels for specific Delivery Windows and Hard Goods'
                        category='Quote')
    
    public static List<Results> execute (List<requests> requestList) {
        //List<ID> quoteIds = requestList.get(0).quoteIds;

        System.debug('IN execute_requestList.size::: ' + requestList.size());
        for(Requests request : requestList){
            resetVariables();
            countRequests++;
            System.debug('IN execute_ForLoopRList_countRequests::: ' + countRequests);
            
            InventoryUtilsClass.processQuoteLine(
                request.quoteIds
                ,currentDW
                ,mProductToDetails
                ,uniqueKeyToDetails
                ,uniqueKeyToDwStartDate
                ,uniqueKeys);
            system.debug('Post QL Loop_mProductToDetails::: ' +mProductToDetails.size());

            if(!mProductToDetails.isEmpty()){
                InventoryUtilsClass.processPrintUnitISBNs(
                    mProductToDetails.keySet()
                    ,mProductToDetails
                    ,uniqueKeyToDetails
                    ,uniqueKeyToDwStartDate
                    ,uniqueKeys);
            }
            
            if(!uniqueKeys.isEmpty()){
                qFail = InventoryUtilsClass.processUniqueKeys(
                    uniqueKeyToDetails
                    ,uniqueKeys
                    ,qFail
                    ,icList
                    ,uniqueKeyDone
                    ,uniqueKeyDwDone
                    ,uniqueKeyCalcCap);

                system.debug('postHGDW_preRemoval - uniqueKeyToDetails_uniqueKeys::: ' + uniqueKeyToDetails.size() + '_' +  uniqueKeys.size());
                system.debug('postHGDW_preRemoval::: ' + uniqueKeyCalcCap.size());
                uniqueKeyCalcCap.removeAll(uniqueKeyDone);
                //uniqueKeyDwDone.addAll(isbnDone); --UPDATE_24.01.10 - Corrects an issue where ISBN was not specific enough
                system.debug('postHGDW_postRemoval::: ' + uniqueKeyCalcCap.size());
                system.debug('postHGDW_postRemoval - uniqueKeyToDetails_uniqueKeys::: ' + uniqueKeyToDetails.size() + '_' +  uniqueKeys.size());
                
                //removes all ISBNs that already have a Hard Good Delivery Window from the map 
                system.debug('preRemoveKeys_ uniqueKeyDwDone::: ' + uniqueKeyDwDone.size());
                MapHelper.removeKeys(uniqueKeyToDwStartDate, uniqueKeyDwDone);

                //resets uniqueKeyDone for future use
                uniqueKeyDone = new Set<String>();
                
                if(!uniqueKeyToDwStartDate.isEmpty()){
                    System.debug('IN uniqueKeyToDwStartDate nPointer_size() ::: ' + uniqueKeyToDwStartDate.size());
                    //creates Hard Good Delivery Windows for the ISBNs/StartDate that were identified as missing
                    InventoryUtilsClass.createHardGoodDeliveryWindows(uniqueKeyToDwStartDate, false);
                }
                if(!uniqueKeyCalcCap.isEmpty()){
                    InventoryUtilsClass.processHardGoodTransactions(
                        uniqueKeyCalcCap
                        ,currentDW
                        ,uniqueKeyToDetails
                        ,uniqueKeyToHgDetails
                        ,uniqueKeyDone);
                    
                    system.debug('postHGT_preRemoval - uniqueKeyToDetails_uniqueKeys::: ' + uniqueKeyToDetails.size() + '_' +  uniqueKeys.size());
                    system.debug('postHGDW_preRemoval::: ' + uniqueKeyCalcCap.size());
                    uniqueKeyCalcCap.removeAll(uniqueKeyDone);
                    system.debug('postHGDW_postRemoval::: ' + uniqueKeyCalcCap.size());
                    system.debug('postHGDW_postRemoval - uniqueKeyToDetails_uniqueKeys::: ' + uniqueKeyToDetails.size() + '_' +  uniqueKeys.size());
                    uniqueKeyDone = new Set<String>();

                    if(!uniqueKeyCalcCap.isEmpty()){
                        InventoryUtilsClass.processHardGoods(
                            uniqueKeyCalcCap
                            ,uniqueKeyToHgDetails
                            ,uniqueKeyDone);

                        system.debug('nPointer - uniqueKeyToDetails::: ' + uniqueKeyToHgDetails.size());
                        system.debug('nPointer - uniqueKeyToDetails::: ' + uniqueKeyToDetails.size());
                    }
                }

                if(!uniqueKeyToHgDetails.isEmpty()){
                    system.debug('IC2 - IN if_preKeySet:::');
                    Set<String> uniqueKeyCalcCapIc = new Set<String>(uniqueKeyToHgDetails.keySet());
                    system.debug('IC2 - IN if_postKeySet size::: ' + uniqueKeyCalcCapIc.size());

                    qFail = InventoryUtilsClass.createInventoryChecks(
                        uniqueKeyCalcCapIc
                        ,uniqueKeyToHgDetails
                        ,uniqueKeyToDetails
                        ,qFail
                        ,icList);
                }

                result.icList = icList;
                result.Fail = qFail == null ? false : true;
                result.NotApplicable = false;
                System.debug('Results_processed - Quote:fail:size:NA::: '+request.quoteIds[0]+':'+ result.Fail +':'+icList.size()+':'+result.NotApplicable);
                results.add(result); 
            }else{
                System.debug('IN NotApplicable :::');
                result.icList = icList;
                result.Fail = qFail == null ? false : true;
                result.NotApplicable = true;
                System.debug('Results_NotApplicable - Quote:fail:size:NA::: '+request.quoteIds[0]+':'+ result.Fail +':'+icList.size()+':'+result.NotApplicable);
                results.add(result); 
            }
        }
        return results;
    }
    

    public class Requests {
        @InvocableVariable( label='Quote Id' 
                            description='The quote id that will be used to check the inventory of its applicable quoteLines'
                            required=true)
            public List<Id> quoteIds;
    }
    public class Results {
        @InvocableVariable( label='InventoryCapacity Records' 
                            description='Apex-defined object')
            public List<InventoryCapacityClassDescriptor> icList;
        @InvocableVariable( label='Inventory Check - Quote warning' 
                            description='Checkbox - checked to warn that the Quote has at least one Quote Line with inventory issues')
            public boolean Fail;
        @InvocableVariable( label='Inventory Check - No applicable QuoteLines' 
          description='Checkbox - checked to warn that the Quote has no applicable Quote Lines to process')
            public boolean NotApplicable;
    }

    public static void resetVariables() {
        System.debug('IN reset:::');
        mProductToDetails = new Map<ID, InventoryWrapperClass.qDetails>();
        uniqueKeyToDetails = new Map<String, InventoryWrapperClass.qDetails>();
        uniqueKeyToDwStartDate = new Map<String, Date>();
        uniqueKeys = new Set<String>();
        uniqueKeyDone = new Set<String>();
        uniqueKeyDwDone = new Set<String>();
        uniqueKeyCalcCap = new Set<String>();
        currentDW = InventoryUtilsClass.generateStartDW(system.today());
        uniqueKeyToHgDetails = new Map<String, InventoryWrapperClass.hgDetails>();
        icList = new List<InventoryCapacityClassDescriptor>();
        qFail = null;
    }

}