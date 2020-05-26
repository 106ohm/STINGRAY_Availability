Input templates are used by the script inputxml.bash to generate the input xml file used by the script darep.pl.
Each template corresponds to a different scenario.


For each template model, two types of places can be defined:
 - Local places: places local to each replica, such that a replica of the template model
   cannot access to the instance of the place included in another replica.
 - Shared places: places shared among the instances of the template model, such that each
   replica of the template model can access (in read/write mode) to all the dependent
   instances of the place included in the other replicas of the template model

todo: extend using multiple drsv:
- input.tmpl:
 1 template model
 1 r-place defined in the template model
 each instance i of r-place depends/impacts on the (i+1) mod n,...,(i+delta) mod n instances of the same place 

todo:
- input_rj.tmpl:
 1 template model A
 1 r-place defined in A
 1 j-place defined in B
 each instance i of r-place depends/impacts on the (i+1) mod n,...,(i+delta) mod n instances of the same place 
