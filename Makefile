all:	day01 day02 day03 day04 day05 day06 day07-part1 day07-part2 day08 day09 day10 \
	day11-part1 day11-part2 day12-part1 day12-part2 day13-part1 day13-part2 day14-part1 day14-part2 day15 day16 \
	day17-part1 day17-part2 day18-part1 day18-part2 day19 day21 day20

day01: day01.o misc.o quicksort.o
	ld day01.o misc.o quicksort.o -o day01

day02: day02.o misc.o quicksort.o
	ld day02.o misc.o quicksort.o -o day02

day03: day03.o misc.o
	ld day03.o misc.o -o day03

day04: day04.o misc.o quicksort.o
	ld day04.o misc.o quicksort.o -o day04

day05: day05.o misc.o quicksort.o memory.o
	ld day05.o misc.o quicksort.o memory.o -o day05

day06: day06.o misc.o
	ld day06.o misc.o -o day06 -lm

day07-part1: day07-part1.o misc.o quicksort.o
	cc day07-part1.o misc.o quicksort.o -o day07-part1

day07-part2: day07-part2.o misc.o quicksort.o
	cc day07-part2.o misc.o quicksort.o -o day07-part2

day08: day08.o misc.o quicksort.o binsearch.o
	ld day08.o misc.o quicksort.o binsearch.o -o day08

day09: day09.o misc.o memory.o
	ld day09.o misc.o memory.o -o day09

day10: day10.o misc.o 
	cc day10.o misc.o -o day10

day11-part1: day11-part1.o misc.o 
	ld day11-part1.o misc.o -o day11-part1

day11-part2: day11-part2.o misc.o 
	ld day11-part2.o misc.o -o day11-part2

day12-part1: day12-part1.o misc.o memory.o
	ld day12-part1.o misc.o memory.o -o day12-part1

day12-part2: day12-part2.o misc.o redblacktree.o memory.o print.o
	ld -g day12-part2.o misc.o redblacktree.o memory.o print.o -o day12-part2

day13-part1: day13-part1.o misc.o 
	cc day13-part1.o misc.o -o day13-part1

day13-part2: day13-part2.o misc.o
	ld -g day13-part2.o misc.o -o day13-part2

day14-part1: day14-part1.o misc.o 
	cc day14-part1.o misc.o -o day14-part1

day14-part2: day14-part2.o misc.o redblacktree.o memory.o
	ld day14-part2.o misc.o redblacktree.o memory.o -o day14-part2

day15: day15.o misc.o 
	cc day15.o misc.o -o day15

day16: day16.o misc.o queue.o
	ld day16.o misc.o queue.o -o day16

day17-part1: day17-part1.o misc.o memory.o redblacktree.o print.o
	ld day17-part1.o misc.o memory.o redblacktree.o print.o -o day17-part1

day17-part2: day17-part2.o misc.o memory.o redblacktree.o print.o
	ld day17-part2.o misc.o memory.o redblacktree.o print.o -o day17-part2

day18-part1: day18-part1.o misc.o array.o
	cc day18-part1.o misc.o array.o -o day18-part1

day18-part2: day18-part2.o misc.o print.o
	ld day18-part2.o misc.o print.o -o day18-part2

day19: day19.o misc.o quicksort.o binsearch.o memory.o
	ld day19.o misc.o quicksort.o binsearch.o memory.o -o day19

day20: day20.o misc.o quicksort.o memory.o print.o queue.o redblacktree.o
	ld day20.o misc.o quicksort.o memory.o print.o queue.o redblacktree.o -o day20

day21: day21.o misc.o queue.o
	ld day21.o misc.o queue.o -o day21

%.o: %.asm
	as -march=rv64imafdcv -g $< -o $@

