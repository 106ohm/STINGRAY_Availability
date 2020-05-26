# STINGRAY_Availability
Möbius model related to the Tuscany regional project [STINGRAY](https://stingray.isti.cnr.it)

# Brief description
This model requires the [Möbius modeling tool](https://www.mobius.illinois.edu).

# Install
Once Möbius has been installed, you need to add the following code to *mobius_root/Cpp/BaseClasses/Makefile.common*
```makefile
# user defined variables local to each project
ifeq ($(shell test -f $(ROOTDIR)/Makefile.userdef && echo yes),yes)
     include $(ROOTDIR)/Makefile.userdef
endif
```
where *mobius_root* depends on the operating system you are using, e.g., for ubuntu */usr/share/mobius-2.5*.

# Generate atomic and composed models
In *Atomic/MAD* and *Atomic/Weather* you can find the template models. In order to generate the concrete atomic models you need
to run DARep (follow instruction inside *darep/bin*)
