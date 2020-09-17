#include <stdio.h>
#include <prussdrv.h>
#include <pruss_intc_mapping.h>


static void *pruDataMem;
static int* pruDataMem_int;


void init_pru_mem()
{
    pruDataMem_int = (int*)pruDataMem;

}

void show_result()
{
    int i;
    unsigned* pruDataMem_uint = (unsigned*)pruDataMem;

    // pruDataMem_uint[0] is the number of values written afterward
    for(i=0;i<=pruDataMem_uint[0];i++)
    {
        printf("[%d]: %u\n", i, pruDataMem_uint[i]);
    }
}

void map_pru_mem(int pruNum)
{
    //Initialize pointer to PRU data memory
    if (pruNum == 0)
    {
      prussdrv_map_prumem (PRUSS0_PRU0_DATARAM, &pruDataMem);
    }
    else if (pruNum == 1)
    {
      prussdrv_map_prumem (PRUSS0_PRU1_DATARAM, &pruDataMem);
    }

    init_pru_mem();
}




int main(int argc, char** argv)
{
    int ret;
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;

    /* Initialize the PRU */
    prussdrv_init ();

    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }

    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    /* Initialize example */
    int pruNum = 0;
    map_pru_mem(pruNum);

    /* Execute example on PRU */
    char path[] = "./timer.bin";
    printf("Executing %s\n", path);
    if(prussdrv_exec_program (pruNum, path))
    {
        fprintf(stderr, "ERROR: Could not open %s\n", path);
        return 1;
    }

    /* Wait until PRU0 has finished execution */
    printf("Waiting for HALT command.\r\n");
    prussdrv_pru_wait_event (PRU_EVTOUT_0);
    prussdrv_pru_clear_event (PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);

    // check what's returned from the PRU
    show_result();
    
    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable (pruNum);
    prussdrv_exit ();
    return 0;
}
