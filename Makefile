
MAKEFLAGS += " --no-print-directory "

define HELP

    ----------------------------------------------------------------------------
    NOTE: this Makefile creates and maintaines a virtualenv in ./ve !
          You can always delete that virtualenv without side effects.
          But you can also of course also use it for your own purposes.
          'make distclean' will recreate that virtualenv from scratch.

    make install
        use 'pip install' to install in virtualenv in ./ve/

    make pylint
        run pylint check on all python source files in radical/

    make pypi
        create source distribution and upload to pypi

    make test
        run unit tests via pytest

    make docs
        build documentation via sphinx

    make prep_git
        Follow the guidelines to set up and populate a repository on github.

    make prep_rtd
        Follow the guidelines to set up readthedocs

    make prep_pypi
        Follow the guidelines to set up pypi poackaging and upload

    make prep_jenkins
        Follow the guidelines to set up Jenkins testing

    make untempletize
	    Revert the steps done by `NAME=foo make teplatize`.
		THIS IS NOT REVERSIBLE AND MAY REMOVE WORK!
    ----------------------------------------------------------------------------

endef

.PHONY: help
help:
	$(info $(HELP))
	@true



PROJECT_NAME = repex

PWD    = $(shell pwd)
VE     = $(PWD)/ve
PYTHON = $(VE)/bin/python
PIP    = $(VE)/bin/pip
PYLINT = $(VE)/bin/pylint
PYTEST = $(VE)/bin/py.test


.PHONY: install install-pip
install: install-pip
install-pip:: virtualenv
	$(PIP) install --upgrade .


.PHONY: install-py
install-py:: virtualenv
	$(PYTHON) setup.py install .

.PHONY: virtualenv
virtualenv:: $(VE)
$(VE):
	test -d $(VE) || virtualenv $(VE)

.PHONY: test tests
tests:: test
test::  install
	$(PIP) install pytest
	$(PYTHON) setup.py test


.PHONY: sdist
sdist::
	$(PYTHON) setup.py sdist


.PHONY: pypi upload
upload::pypi
pypi::
	$(PYTHON) setup.py sdist upload


.PHONY: doc docs
docs::  doc
doc::   install
	$(PIP) install sphinx
	sh -c '. $(VE)/bin/activate; make -C docs html'


.PHONY: pylint
pylint:: install
	$(PIP) install pylint
	@rm -f pylint.out ;\
	for f in `find radical -name \*.py | grep -v external`; do \
		echo "checking $$f"; \
		( \
	    res=`$(PYLINT) -r n -f text $$f 2>&1 | grep -e '^[FE]:' | grep -v maybe-no-member` ;\
		  test -z "$$res" || ( \
		       echo '----------------------------------------------------------------------' ;\
		       echo $$f ;\
		       echo '----------------------------------------------------------------------' ;\
		  		 echo $$res | sed -e 's/ \([FEWRC]:\)/\n\1/g' ;\
		  		 echo \
		  ) \
		) | tee -a pylint.out; \
	done ; \
	test "`cat pylint.out | wc -c`" = 0 || false && rm -f pylint.out


.PHONY: clean
clean::
	rm -rf $(PROJECT_NAME).egg-info/ build/ temp/ dist/ MANIFEST
	rm -f  $(PROJECT_NAME)/{VERSION,VERSION.git} pylint.out
	make -C docs clean
	find . -name \*.pyc      -exec rm -vf {} \;
	find . -name __pycache__ -exec rm -vf {} \;
	find . -name \*.sw[pov]  -exec rm -vf {} \;
	find . -name \*~         -exec rm -vf {} \;


.PHONY: distclean
distclean:: clean
	rm -rf ve
	make virtualenv


.PHONY: prep_git
prep_git:
	@echo
	@echo "---------------------------------------------------------------------------------"
	@echo "After each step, press <enter>."
	@echo "You can iterrupt (and then restart( via <ctrl-C>"
	@echo
	@echo "  * Create an account (or sign in) on http://github.com"
	@read reply
	@echo "  * Join the RADICAL project at https://github.com/radical-cybertools/ "
	@echo "    On Problems, contact Ole or Andre (ole.weidner@rutgers.edu, andre@merzky.net)."
	@read reply
	@echo "  * Create a new repository in the RADICAL project named 'radical.repex' at"
	@echo "        https://github.com/organizations/radical-cybertools/repositories/new "
	@echo "    On Problems, contact Ole or Andre (ole.weidner@rutgers.edu, andre@merzky.net)."
	@read reply
	@echo "  * Run the following set of git commands:"
	@echo "        git init"
	@echo "        git add * .gitignore"
	@echo "        git commit -m  'initial commit'"
	@echo "        git remote add origin git@github.com:radical-cybertools/radical.repex.git"
	@echo "        git push origin master"
	@read reply
	@echo "  * Check the README content on "
	@echo "        https://github.com/radical-cybertools/radical.repex"
	@read reply
	@echo "  * Make sure to 'watch' that repository (button on upper right)"
	@read reply
	@echo "  * Use the issue tracker on github, at "
	@echo "        https://github.com/radical-cybertools/radical.repex/issues"
	@read reply
	@echo "  * Git setup is now done."
	@read reply
	@echo "---------------------------------------------------------------------------------"
	@echo


.PHONY: prep_pypi
prep_pypi:
	@echo
	@echo "---------------------------------------------------------------------------------"
	@echo "After each step, press <enter>."
	@echo "You can iterrupt (and then restart( via <ctrl-C>"
	@echo
	@echo "  * Create an account (or sign in) on http://pypi.python.org/pypi/"
	@echo "    On Problems, contact Ole or Andre (ole.weidner@rutgers.edu, andre@merzky.net)."
	@read reply
	@echo "  * create a '$$HOME/.pypirc' with the following content:"
	@echo
	@echo "        [pypirc]"
	@echo "        servers = pypi"
	@echo
	@echo "        [server-login]"
	@echo "        username:<your_username>"
	@echo "        password:<your_password>"
	@read reply
	@echo "  * Fill missing details in 'setup.py'.  Check for TODO markers."
	@read reply
	@echo "  * Prepare a release of your software."
	@echo "    That usually includes the following steps:"
	@echo "      * make sure all tests pass"
	@echo "      * merge devel into master"
	@echo "      * update the VERSION file, CHANGES.md; then commit and push."
	@echo "      * tag the release in git, via 'git tag v0.2'"
	@echo "      * push tag to github, via 'git push --tags'"
	@read reply
	@echo "  * Upload to pypi via the following command:"
	@echo "        make pypi"
	@read reply
	@echo "  * Make sure the uploaded package works as expected:"
	@echo "      * create a new virtualenv via 'virtualenv test_ve'"
	@echo "      * use that virtualenv via 'source test_ve/bin/activate'"
	@echo "      * install your package from pypi, via 'pip install --upgrade radical.repex'"
	@echo "      * ensure basic functionality, eg. via 'radical-repex-version'"
	@read reply
	@echo "  * Pypi setup is now done."
	@read reply
	@echo "---------------------------------------------------------------------------------"
	@echo


.PHONY: prep_readthedocs
prep_readthedocs: prep_rtd
.PHONY: prep_rtd
prep_rtd:
	@echo
	@echo "---------------------------------------------------------------------------------"
	@echo "After each step, press <enter>."
	@echo "You can iterrupt (and then restart( via <ctrl-C>"
	@echo
	@echo "  * Create an account (or sign in) on https://readthedocs.org/"
	@echo "    On Problems, contact Ole or Andre (ole.weidner@rutgers.edu, andre@merzky.net)."
	@read reply
	@echo "  * select 'Add Project' from top-left drop-down menu"
	@read reply
	@echo "  * use the following settings:"
	@echo "      * name     : radical.repex"
	@echo "      * git url  : https://github.com/radical-cybertools/radical.repex.git"
	@echo "      * doc type : sphinx"
	@echo "      * home page: https://github.com/radical-cybertools/radical.repex/"
	@read reply
	@echo
	@echo "  * after project creation, select the 'Admin' tab and set/add:"
	@echo "      * Advanced Settings: 'use virtualenv': yes"
	@echo "      * Advanced Settings: 'privacy level' : public"
	@echo "      * Notifications    : 'email'         : <your email>"
	@echo "      * Maintainers      : 'add'           : radical"
	@echo "    The last item will add the generic 'radical' rtd account as manager."
	@read reply
	@echo "  * RTD setup is now done."
	@read reply
	@echo "---------------------------------------------------------------------------------"
	@echo

.PHONY: prep_jenkins
prep_jenkins:
	@echo
	@echo "---------------------------------------------------------------------------------"
	@echo "After each step, press <enter>."
	@echo "You can iterrupt (and then restart( via <ctrl-C>"
	@echo
	@echo "  * Create an account on testing.saga-project.org."
	@echo "    Contact Ole or Andre (ole.weidner@rutgers.edu, andre@merzky.net)."
	@read reply
	@echo "  * Use that account to login to http://testing.saga-project.org:8080/"
	@read reply
	@echo "  * Add new Jenkins job at http://testing.saga-project.org:8080/view/All/newJob"
	@echo "      * name     : radical.repex"
	@echo "      * copy job : radical.utils"
	@read reply
	@echo "  * In the job configuration, search for 'utils' and replace with 'repex'."
	@read reply
	@echo "  * Add you email to the mail notifications."
	@read reply
	@echo "  * Jenkins setup is now done."
	@read reply
	@echo "---------------------------------------------------------------------------------"
	@echo


.PHONY: untemplatize
untemplatize:
	@test -d .git.radical.template || (echo "original .git missing" && false)
	@rm -rf .git
	@mv .git.radical.template .git
	@git reset --hard HEAD
	-@rm -rf src/radical/$(PROJECT_NAME)/
	-@rm -f  bin/radical-$(PROJECT_NAME)-version
	-@rm -f  docs/source/module_$(PROJECT_NAME).rst
	-@rm -f tests/unittests/test_$(PROJECT_NAME).py

