LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

PACKAGE fsm_states_pkg IS
    type state_type is (start, practice, easy, medium, hard, game_over);

END PACKAGE fsm_states_pkg;
    