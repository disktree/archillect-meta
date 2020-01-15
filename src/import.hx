
import haxe.io.Bytes;

import om.Json;
import om.Nil;
import om.Thread;
import Sys.print;
import Sys.println;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using om.StringTools;

#if sys
import Sys.print;
import Sys.println;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

#if nodejs
import js.Node.process;
import js.lib.Promise;
import js.node.Fs;
import js.node.Https;
#end