/**
 * @description       : Used to keep track of completed/not completed tasks
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 10-03-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CaseTally {

        public Decimal TasksCompleted = 0;
        public Decimal TasksToComplete = 0;

        /**
        * @description Adds a tally to the current tally
        * @author Brian Ezell (Simply EZ) | 09-21-2024 
        * @param newTally 
        **/
        public void addTally(CaseTally newTally) {
            this.TasksCompleted += newTally.TasksCompleted;
            this.TasksToComplete += newTally.TasksToComplete;
        }

        /**
        * @description Adds a value to the current tally by values
        * @author Brian Ezell (Simply EZ) | 09-21-2024 
        * @param completed 
        * @param toComplete 
        **/
        public void addTallyValues(Decimal completed, Decimal toComplete) {
            this.TasksCompleted += completed;
            this.TasksToComplete += toComplete;
        }
}