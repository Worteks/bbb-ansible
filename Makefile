DEPLOYMENT=drbd

-include Makefile.cust

.PHONY: deploy
deploy: init
	@@if ! ansible --version >/dev/null 2>&1; then \
	    export PATH=$HOME/.local/bin:$PATH; \
	    if ! ansible --version >/dev/null 2>&1; then \
		echo CRITICAL: could not find Ansible; \
	    fi; \
	fi; \
	ansible-playbook bootstrap.yaml

.PHONY: init
init:
	@@if ! ansible --version >/dev/null 2>&1; then \
	    pip3 install -r requirements.txt; \
	fi
	@@if ! ls group_vars/ >/dev/null 2>&1; then \
	    if test -d inventory/group_vars-$(DEPLOYMENT) -a -s inventory/hosts-$(DEPLOYMENT); then \
		ln -sf inventory/group_vars-$(DEPLOYMENT) group_vars; \
		ln -sf inventory/hosts-$(DEPLOYMENT) hosts; \
	    fi; \
	fi

.PHONY: lint
lint: init
	@@ansible-lint -c ./.ansible-lint bootstrap.yaml

.PHONY: reset
reset:
	@@rm -f hosts group_vars .ansible-logs
