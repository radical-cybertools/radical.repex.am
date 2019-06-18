
import time

import threading as mt

import radical.entk  as re
import radical.utils as ru


from .replica import Replica

t_0 = time.time()


# ------------------------------------------------------------------------------
#
class Exchange(re.AppManager):

    _glyphs = {re.states.INITIAL:    '+',
               re.states.SCHEDULING: '|',
               re.states.SUSPENDED:  '-',
               re.states.DONE:       ' ',
               re.states.FAILED:     '!',
               re.states.CANCELED:   'X'}


    # --------------------------------------------------------------------------
    #
    def __init__(self, ensemble_size, exchange_size, md_cycles):

        self._en_size = ensemble_size
        self._ex_size = exchange_size
        self._cycles  = md_cycles

        self._lock = mt.Lock()
        self._log  = ru.Logger('radical.repex.exc')
        self._dout = open('dump.log', 'a')

        re.AppManager.__init__(self, autoterminate=False, port=5672)
        self.resource_desc = {"resource" : 'local.localhost',
                              "walltime" : 30,
                              "cpus"     : 16}

        self._replicas = list()
        self._waitlist = list()

        # create the required number of replicas
        for i in range(self._en_size):

            replica = Replica(check_ex  = self._check_exchange,
                              check_res = self._check_resume,
                              rid       = i)

            self._replicas.append(replica)

        self._dump(msg='startup')

        # run the replica pipelines
        self.workflow = set(self._replicas)
        self.run()


    # --------------------------------------------------------------------------
    #
    def _dump(self, msg=None, special=None, glyph=None ):

        if not msg:
            msg = ''

        self._dout.write(' | %7.2f |' % (time.time() - t_0))
        for r in self._replicas:
            if special and r in special:
                self._dout.write('%s' % glyph)
            else:
                self._dout.write('%s' % self._glyphs[r.state])
        self._dout.write('| %s\n' % msg)
        self._dout.flush()


    # --------------------------------------------------------------------------
    #
    def terminate(self):

        self._log.debug('exc term')
        self._dump(msg='terminate', special=self._replicas, glyph='=')
        self._dout.close()

        # we are done!
        self.resource_terminate()


    # --------------------------------------------------------------------------
    #
    def _check_exchange(self, replica):

        # This method races when concurrently triggered by multpiple replicas,
        # and it should be guarded by a lock.
        with self._lock:

            self._log.debug('=== %s check exchange : %d >= %d?',
                      replica.rid, len(self._waitlist), self._ex_size)

            self._waitlist.append(replica)

            exchange_list = self._find_exchange_list()

            if not exchange_list:
                # nothing to do, Suspend this replica and wait until we get more
                # candidates and can try again
                self._log.debug('=== %s no  - suspend', replica.rid)
                replica.suspend()
                self._dump()
                return

            self._log.debug('=== %s yes - exchange', replica.rid)
            msg = " > %s: %s" % (replica.rid, [r.rid for r in exchange_list])
            self._dump(msg=msg, special=exchange_list, glyph='v')

            # we have a set of exchange candidates.  The current replica is
            # tasked to host the exchange task.
            replica.add_ex_stage(exchange_list)


    # --------------------------------------------------------------------------
    #
    def _find_exchange_list(self):
        '''
        This is the core algorithm: out of the list of eligible replicas, select
        those which should be part of an exchange step
        '''

        if len(self._waitlist) < self._ex_size:

            # not enough replicas to attempt exchange
            return

        # we have enough replicas!  Remove all as echange candidates from the
        # waitlist and return them!
        exchange_list = list()
        for r in self._waitlist:
            exchange_list.append(r)

        # empty the waitlist to start collecting new cccadidates
        self._waitlist = list()

        return exchange_list


    # --------------------------------------------------------------------------
    #
    def _check_resume(self, replica):

        self._dump()
        self._log.debug('=== %s check resume', replica.rid)

        resumed = list()  # list of resumed replica IDs

        msg = " < %s: %s" % (replica.rid, [r.rid for r in replica.exchange_list])
        self._dump(msg=msg, special=replica.exchange_list, glyph='^')

        # after a successfull exchange we revive all participating replicas.
        # For those replicas which did not yet reach min cycles, add an md
        # stage, all others we let die and add a new md stage for them.
        for _replica in replica.exchange_list:

            if _replica.cycle <= self._cycles:
                _replica.add_md_stage()

            # Make sure we don't resume the current replica
            if replica.rid != _replica.rid:

                self._log.debug('=== %s resume', _replica.rid)
                _replica.resume()
                resumed.append(_replica.uid)

        return resumed


# ------------------------------------------------------------------------------

