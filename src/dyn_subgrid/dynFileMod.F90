module dynFileMod
  !---------------------------------------------------------------------------
  ! !DESCRIPTION:
  ! Contains a derived type that is essentially a file_desc_t, but also adds a
  ! time_info_type object. This is used for tracking time information for a single
  ! dynamic landuse file.
  !
  ! !USES:
  use shr_log_mod    , only : errMsg => shr_log_errMsg
  use dynTimeInfoMod , only : time_info_type, year_position_type
  use ncdio_pio      , only : file_desc_t, ncd_pio_openfile, ncd_inqdid, ncd_inqdlen, ncd_io
  use abortutils     , only : endrun
  implicit none
  private
  !
  ! !PUBLIC TYPES:
  public :: dyn_file_type

  type, extends(file_desc_t) :: dyn_file_type
     type(time_info_type) :: time_info ! time information for this file
  end type dyn_file_type

  interface dyn_file_type
     module procedure constructor  ! initialize a new dyn_file_type object
  end interface dyn_file_type

  character(len=*), parameter, private :: sourcefile = &
       __FILE__
  !-----------------------------------------------------------------------

contains
  
  ! ======================================================================
  ! Constructors
  ! ======================================================================

  !-----------------------------------------------------------------------
  type(dyn_file_type) function constructor(filename, year_position)
    !
    ! !DESCRIPTION:
    ! Initialize a dyn_file_type object
    !
    ! Opens the file associated with filename for reading, reads the 'YEAR' variable from
    ! this file (assumed to have dimension 'time'), and initializes a dyn_time_info object
    ! based on this YEAR variable and the current model year.
    !
    ! year_position is a flag saying how to obtain the model year relative to the current
    ! timestep; it must be one of the parameters defined in dynTimeInfoMod (e.g.,
    ! YEAR_POSITION_START_OF_TIMESTEP or YEAR_POSITION_END_OF_TIMESTEP)
    !
    ! !USES:
    use fileutils        , only : getfil
    !
    ! !ARGUMENTS:
    character(len=*)         , intent(in) :: filename
    type(year_position_type) , intent(in) :: year_position
    !
    ! !LOCAL VARIABLES:
    character(len=256) :: locfn      ! local file name
    integer :: ier                   ! error code
    integer :: ntimes                ! number of time samples
    integer :: varid                 ! netcdf variable ID
    integer, allocatable :: years(:) ! years in the file

    character(len=*), parameter :: subname = 'dyn_file_type constructor'
    !-----------------------------------------------------------------------

    ! Obtain file

    call getfil(filename, locfn, 0)
    call ncd_pio_openfile(constructor, locfn, 0)
    
    ! Obtain years

    call ncd_inqdid(constructor, 'time', varid)
    call ncd_inqdlen(constructor, varid, ntimes)
    allocate(years(ntimes), stat=ier)
    if (ier /= 0) then
       call endrun(msg=' allocation error for years'//errMsg(sourcefile, __LINE__))
    end if
    call ncd_io(ncid=constructor, varname='YEAR', flag='read', data=years)
    
    ! Initialize object containing time information for the file

    constructor%time_info = time_info_type(years, year_position)

    deallocate(years)

  end function constructor

end module dynFileMod
