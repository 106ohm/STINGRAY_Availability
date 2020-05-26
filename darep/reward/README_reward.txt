
You can define automatically parametric reward measures as a function of an index i, i=0,...,n, by generating and editing the template file .pvm for an already defined performance variable:

   1. From the GUI of Mobius, define a performance variable to use as template.

   2. Generate the base templates for the reward model and the performance variable, by running the script:

	genRewardPVMtemplate.pl <Project name> <Reward model name> <Performance variable name>
	
   3. Customize the template generated at step 2. for the performance variable, by using ${i} as index of the performance variable (e.g., use P_${i}, to define the performance variables: P_1, P_2, ...):

   4. Generate the reward model file .pvm, based on the templates generated and customized in the above steps, by running the script:

	genRewardPVM.pl <Project name> <Reward model name> <Reward model template name> <Performance variable template name> <imin> <imax>	
   
   5. Replace the file .pvm of the reward model with the file .pvm generated at step 4.
   
   6. From the GUI of Mobius, open the reward model and save it.

   7. From the GUI of Mobius, delete the variable used as template.

The results of the above steps is to add to the input reward model new performance variables defined as a function of an index i.
For each new performance variable defined as a function of a parameter i repeat the above steps.


Commands:

step 2:
cd darep/reward/templates
./bin/genRewardPVMtemplate.pl parallelWorkingStations_ssa PVM EA1_rep

step 4:
./bin/genRewardPVM.pl parallelWorkingStations_ssa PVM templates/PVM-template.pvm ./templates/PVM-template-EA1_rep.pvm 0 99
