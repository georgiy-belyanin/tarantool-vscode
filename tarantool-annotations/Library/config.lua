---@meta

---# Builtin `config` module
---
---*Since 3.0.0*
---
---The `config` module provides the ability to work with an instance's configuration.
---
---For example, you can determine whether the current instance is up and running without errors after applying the [cluster's configuration](doc://configuration_overview).
---
---By using the `config.storage` [role](doc://configuration_application_roles), you can set up a Tarantool-based [centralized configuration storage](doc://configuration_etcd) and interact with this storage using the `config` module API.
local config = {}


---Get a configuration applied to the current or remote instance.
---
---Note the following differences between getting a configuration for the current and remote instance:
---* For the current instance, `get()` returns its configuration considering [environment variables](doc://configuration_environment_variable).
---* For a remote instance, `get()` only considers a cluster configuration and ignores environment variables.
---
---**Examples:**
---
---The example below shows how to get the full instance configuration:
---
--- ```tarantoolsession
--- app:instance001> require('config'):get()
--- ---
--- - fiber:
---   io_collect_interval: null
---   too_long_threshold: 0.5
---   top:
---   enabled: false
---   # Other configuration values
---   # ...
--- ```
---
---This example shows how to get an `iproto.listen` option value:
---
--- ```tarantoolsession
--- app:instance001> require('config'):get('iproto.listen')
--- ---
--- - - uri: 127.0.0.1:3301
--- ...
--- ```
---
---`config.get()` can also be used in [application code](doc://configuration_application) to get the value of a custom configuration option.
---
---@param param string | string[]
---@param opts { instance?: string }
---@return any
function config:get(param, opts) end

---@alias config.info.status
---| "ready" # the configuration is applied successfully
---| "check_warnings" # the configuration is applied with warnings
---| "check_errors" # the configuration cannot be applied due to configuration errors

---@class config.alert
---@field type "warn" | "error"
---@field message string

---@class config.info.meta
---@field etcd? { mod_revision: { [string]: number }, revision: integer }
---@field storage? { mod_revision: { [string]: number }, revision: integer }

---@class config.info.meta.v2
---@field last config.info.meta
---@field active config.info.meta

---@class config.info
---@field status config.info.status
---@field alerts config.alert[]
---@field meta config.info.meta

---@class config.info.v2: config.info
---@field meta config.info.meta.v2

---Get the current instance's state in regard to configuration.
---
---Below are a few examples demonstrating how the `info()` output might look.
---
---**Example: no configuration warnings or errors**
---
---In the example below, an instance's state is `ready` and no warnings are shown:
---
--- ```tarantoolsession
--- app:instance001> require('config'):info('v2')
--- ---
--- - status: ready
---   meta:
---     last: &0 []
---     active: *0
---   alerts: []
--- ...
--- ```
---
---**Example: configuration warnings**
--- 
---In the example below, the instance's state is `check_warnings`.
---The `alerts` section informs that privileges to the `bands` space for `sampleuser` cannot be granted because the `bands` space has not been created yet:
--- 
--- ```tarantoolsession
--- app:instance001> require('config'):info('v2')
--- ---
--- - status: check_warnings
---   meta:
---     last: &0 []
---     active: *0
---   alerts:
---   - type: warn
---     message: box.schema.user.grant("sampleuser", "read,write", "space", "bands") has
---     failed because either the object has not been created yet, a database schema
---     upgrade has not been performed, or the privilege write has failed (separate
---     alert reported)
---     timestamp: 2024-07-03T18:09:18.826138+0300
--- ...
--- ```
---
---This warning is cleared when the `bands` space is created.
---
---**Example: configuration errors**
---
---In the example below, the instance's state is `check_errors`.
---The `alerts` section informs that the `log.level` configuration option has an incorrect value:
---
--- ```tarantoolsession
--- app:instance001> require('config'):info('v2')
--- ---
--- - status: check_errors
---   meta:
---     last: []
---     active: []
---   alerts:
---   - type: error
---     message: '[cluster_config] log.level: Got 8, but only the following values are
---     allowed: 0, fatal, 1, syserror, 2, error, 3, crit, 4, warn, 5, info, 6, verbose,
---     7, debug'
---     timestamp: 2024-07-03T18:13:19.755454+0300
--- ...
--- ```
--- 
---**Example: configuration errors (centralized configuration storage)**
--- 
---In this example, the `meta` field includes information about a [centralized storage](doc://configuration_etcd) the instance takes a configuration from:
--- 
--- ```tarantoolsession
--- app:instance001> require('config'):info('v2')
--- ---
--- - status: check_errors
---   meta:
---     last:
---       etcd:
---         mod_revision:
---           /myapp/config/all: 5
---         revision: 5
---     active:
---       etcd:
---         mod_revision:
---           /myapp/config/all: 2
---         revision: 4
---   alerts:
---   - type: error
---     message: 'etcd source: invalid config at key "/myapp/config/all": [cluster_config]
---     groups.group001.replicasets.replicaset001.instances.instance001.log.level: Got
---     8, but only the following values are allowed: 0, fatal, 1, syserror, 2, error,
---     3, crit, 4, warn, 5, info, 6, verbose, 7, debug'
---     timestamp: 2024-07-03T15:22:06.438275Z
---     ...
--- ```
---
---@param version? 'v1'
---@return config.info
---@overload fun(version: 'v2'): config.info.v2
function config:info(version) end


---Get a URI of the current or remote instance.
---
---**Note:** the resulting URI object can be passed to the [connect()](lua://net_box-connect) function.
---
---**Example:**
---
---The example below shows how to get a URI used to advertise `storage-b-003` to other cluster members:
---
--- ```lua
--- local config = require('config')
--- config:instance_uri('peer', { instance = 'storage-b-003' })
--- ```
---
---@param uri_type 'peer' | 'sharding'
---@param opts { instance?: string }
---@return uri
function config:instace_uri(uri_type, opts) end

return config
