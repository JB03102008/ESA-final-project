function StrongmanGameStop()
% Simple stop script for StrongmanGame main script - version 1.0
% Made by UTWENTE-BSC-EE-ESA group 3
% Version: 1.0
stop(timerfindall); delete(timerfindall);
cancelAll(parallel.FevalFuture);
end