package main

import (
    "encoding/csv"
    "fmt"
    "io"
    "log"
    "os"
    "strconv"
)

const A_full=2-1
const LDSWn=3-1
const UDSWn=5-1
const CPU_DIN=8-1
const CPU_DOUT=9-1
const FRAMECNT=16-1

type Sim struct {
    file *os.File;
    rdr *csv.Reader;
    linecnt int;
    record, pending []string
}

func open_sim(path string) *Sim {
    s := Sim{ }
    fin, err := os.Open(path)
    if err != nil {
        log.Fatal("Cannot open ", path)
    }
    s.file = fin
    s.linecnt = 2
    s.rdr = csv.NewReader(s.file)
    _,err = s.rdr.Read()
    if err != nil {
        log.Fatal("Cannot read header of ", path)
    }
    // Read until past 400us
    for {
        var err error
        s.record, err = s.rdr.Read()
        if err == io.EOF {
            log.Fatal("File ends before reaching 400us")
        }
        if err != nil {
            log.Fatal(err)
        }
        s.linecnt++
        time,_ := strconv.ParseFloat(s.record[0],64 )
        if time >= 400000 {
            break
        }
    }
    return &s
}

func (s *Sim) find_write() bool {
    for {
        var err error
        s.record, err = s.rdr.Read()
        s.linecnt++
        if err == io.EOF {
            return false
        }
        if err != nil {
            log.Fatal(err)
        }
        if s.record[LDSWn] == "0" ||
           s.record[UDSWn] == "0" {
            // found it
            for {
                // keep advancing until past the write
                var raux []string
                raux, err = s.rdr.Read()
                if err == io.EOF {
                    return true
                }
                s.linecnt++
                if raux[LDSWn] == "1" &&
                   raux[UDSWn] == "1" {
                    return true
                }
                if raux[A_full] != s.record[A_full] {
                    log.Fatal("Address bus changed during write")
                }
                if raux[CPU_DOUT] != s.record[CPU_DOUT] {
                    log.Fatal("CPU output changed during write")
                }
            }
        }
    }
    return true
}

func cmp_record( j68, fx68 []string ) string {
    bad := ""
    if j68[A_full] != fx68[A_full] {
        bad = "Address bus diverged"
    }
    if j68[UDSWn] != fx68[UDSWn] {
        bad = "Different UDSWn"
    }
    if j68[LDSWn] != fx68[LDSWn] {
        bad = "Different LDSWn"
    }
    j68_cpudout, _ := strconv.ParseInt(j68[CPU_DOUT],16,32)
    fx68_cpudout, _ := strconv.ParseInt(fx68[CPU_DOUT],16,32)
    if j68[LDSWn]=="0" {
        if (j68_cpudout&0xff) != (fx68_cpudout&0xff) {
            bad = "Different low data during low write"
        }
    }
    if j68[UDSWn]=="0" {
        if ((j68_cpudout>>8)&0xff) != ((fx68_cpudout>>8)&0xff) {
            bad = "Different high data during high write"
        }
    }
    return bad
}

func compare( j68, fx68 *Sim ) bool {
    bad := ""
    if j68.pending == nil {
        bad = cmp_record( j68.record, fx68.record )
        if bad != "" {
            j68.pending = j68.record
            fx68.pending = fx68.record
            return true // prevent A bus inversion for 32-bit writes
        }
    } else {
        bad = cmp_record( j68.record, fx68.pending )
        if bad == "" {
            bad = cmp_record( j68.pending, fx68.record )
        }
    }

    if bad != "" {
        fmt.Printf("%s at frame %s/%s, times (fx68/j68) %s  /  %s \n",
            bad, fx68.record[FRAMECNT], j68.record[FRAMECNT], fx68.record[0], j68.record[0])
        fmt.Printf("A_full   %s  /  %s\n", fx68.record[A_full], j68.record[A_full])
        fmt.Printf("cpu_dout %s  /  %s\n", fx68.record[CPU_DOUT], j68.record[CPU_DOUT])
        fmt.Printf("DSWn %s%s  /  %s%s\n", fx68.record[UDSWn], fx68.record[LDSWn],
            j68.record[UDSWn], j68.record[LDSWn])
        //fmt.Printf("cpu_dout %d  /  %d\n", fx68_cpudout, j68_cpudout)
        return false
    } else {
        j68.pending = nil
        fx68.pending = nil
        return true
    }
}

func main() {
    basename:="new"
    j68  := open_sim(basename+"_j68.csv")
    fx68 := open_sim(basename+"_fx68.csv")
    defer j68.file.Close()
    defer fx68.file.Close()

    for {
        if !j68.find_write() {
            break
        }
        if !fx68.find_write() {
            fmt.Println("unmatched writting: end of file")
            break
        }
        if !compare( j68, fx68 ) {
            break
        }
    }
    fmt.Println("Both simulations are equal")
}