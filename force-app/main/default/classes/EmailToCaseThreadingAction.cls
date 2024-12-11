public without sharing class EmailToCaseThreadingAction {
    public static Boolean enableDebug = DebugHelper.isDebugEnabled();

    @InvocableMethod(   label       = 'Get Threading Token' 
                        description = 'Get formatted threading token for a Case record'
                        category    = 'Case')
    
    public static List<Results> getThreadingToken(List<Requests> caseIds) {
        
        List<Results> results = new List<Results>();
        Results result = new results();

        // List<String> threadingTokens = new List<String>();
        
        if(enableDebug) {
            System.debug('EtoCThreadingAct::: caseIds.size::: ' + caseIds.size());
        }
        
        if(caseIds == null || caseIds.isEmpty()) {
            if(enableDebug) {
                System.debug('EtoCThreadingAct::: No case Ids provided');
            }
            return results;
        }
        
        for (Requests request : caseIds) {
            if(enableDebug) {
                System.debug('EtoCThreadingAct_caseId::: ' + request.caseId);
            }
            String token = getFormattedThreadingToken(request.caseId);
            result.threadingToken=token;
            results.add(result);
        }
        
        return results;
    }

    public class Requests {
        @InvocableVariable( label       = 'Case Ids' 
                            description = 'The list of Case Ids that will be processed to get the threading token'
                            required    = true)
            public Id caseId;
    }

    public class Results {
        @InvocableVariable( label       = 'Threading Token' 
                            description = 'List of threading tokens for the Case records')
            public String threadingToken;
    }
    
    private static String getFormattedThreadingToken(Id caseId) {
        String threadingToken;

        if(enableDebug) {
            System.debug('EtoCThreadingAct.getFormThreadToken_caseId::: ' + caseId);
        }
        
        threadingToken = EmailMessages.getFormattedThreadingToken(caseId);
        return threadingToken;
    }
}