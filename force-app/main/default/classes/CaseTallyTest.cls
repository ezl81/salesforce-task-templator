/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-21-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest 
private class CaseTallyTest {

    @IsTest
    private static void testCaseTally() {
        CaseTally tally = new CaseTally();
        CaseTally tally2 = new CaseTally();

        tally.TasksToComplete = 5;
        tally.TasksCompleted = 3;

        tally2.TasksCompleted = 1;
        tally2.TasksToComplete = 1;

        tally.addTally(tally2);

        Assert.isTrue(tally.TasksCompleted > 3, 'CaseTally did not add correctly');
    }

    @IsTest
    private static void testCaseTallyValues() {
        CaseTally tally = new CaseTally();

        tally.TasksToComplete = 5;
        tally.TasksCompleted = 3;

        tally.addTallyValues(1, 1);

        Assert.isTrue(tally.TasksCompleted > 3, 'CaseTally did not add correctly');
    }

}