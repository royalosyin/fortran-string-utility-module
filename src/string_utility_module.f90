!===============================================================================
module string_utility_module
!===============================================================================
  use, intrinsic :: iso_fortran_env
  implicit none

  private

  ! public procedures:
  public :: str_convert_to_lowercase
  public :: str_convert_to_uppercase
  public :: str_is_integer
  public :: str_is_real
  public :: str_loc_end_token
  public :: str_loc_next_real
  public :: str_loc_next_space
  public :: str_loc_next_token
  public :: str_loc_start_token
  public :: str_lowercase
  public :: str_parse_next_token
  public :: str_uppercase

  ! parameters:
  integer, parameter :: CK = selected_char_kind('DEFAULT')
  !integer, parameter :: LK = logical_kinds(min(3,size(logical_kinds)))

  character(kind=CK,len=*), parameter :: SPACE           = ' '
  character(kind=CK,len=*), parameter :: TAB             = achar(9)
  character(kind=CK,len=*), parameter :: NEWLINE         = achar(10)
  character(kind=CK,len=*), parameter :: VERTICAL_TAB    = achar(11)
  character(kind=CK,len=*), parameter :: FORM_FEED       = achar(12)
  character(kind=CK,len=*), parameter :: CARRIAGE_RETURN = achar(13)

  character(kind=CK,len=*), parameter :: SPACES = SPACE//TAB//NEWLINE &
    //VERTICAL_TAB//FORM_FEED//CARRIAGE_RETURN

  character(kind=CK,len=*), parameter :: LETTERS_LC = 'abcdefghijklmnopqrstuvwxyz'
  character(kind=CK,len=*), parameter :: LETTERS_UC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  character(kind=CK,len=*), parameter :: LETTERS    = LETTERS_LC//LETTERS_UC

  character(kind=CK,len=*), parameter :: COMMA     = ','
  character(kind=CK,len=*), parameter :: SEMICOLON = ';'
  character(kind=CK,len=*), parameter :: COLON     = ':'

  character(kind=CK,len=*), parameter :: BRACKET_LEFT  = '['
  character(kind=CK,len=*), parameter :: BRACKET_RIGHT = ']'

  character(kind=CK,len=*), parameter :: PARENTHESES_LEFT  = '('
  character(kind=CK,len=*), parameter :: PARENTHESES_RIGHT = ')'

  character(kind=CK,len=*), parameter :: DELIMITERS = SPACES//COMMA//COLON &
    //SEMICOLON//BRACKET_LEFT//BRACKET_RIGHT//PARENTHESES_LEFT//PARENTHESES_RIGHT

contains

!===============================================================================
! ch_is_digit:
!
!   Returns .TRUE. if the given character is a digit character.
!
  pure function ch_is_digit( ch ) result( ans )
    character(kind=CK,len=1), intent(in) :: ch
    logical :: ans

    select case (ch)
    case ('0':'9')
      ans = .true.
    case default
      ans = .false.
    end select
  end function ch_is_digit
!===============================================================================

!===============================================================================
! ch_is_letter:
!
!   Returns .TRUE. if the given character is either a lower case or upper case
!   letter.
!
  pure function ch_is_letter( ch ) result( ans )
    character(kind=CK,len=1), intent(in) :: ch
    logical :: ans

    select case (ch)
    case ('a':'z','A':'Z')
      ans = .true.
    case default
      ans = .false.
    end select
  end function ch_is_letter
!===============================================================================

!===============================================================================
! ch_is_lowercase:
!
!   Returns .TRUE. if the given character is a lower case letter.
!
  pure function ch_is_lowercase( ch ) result( ans )
    character(kind=CK,len=1), intent(in) :: ch
    logical :: ans

    select case (ch)
    case ('a':'z')
      ans = .true.
    case default
      ans = .false.
    end select
  end function ch_is_lowercase
!===============================================================================

!===============================================================================
! ch_is_space:
!
!   Returns .TRUE. if the given character is a space character. Either a space,
!   tab, newline, vertical tab, form feed, or carriage return character.
!
  pure function ch_is_space( ch ) result( ans )
    character(kind=CK,len=1), intent(in) :: ch
    logical :: ans

    select case (ch)
    case (space,tab,newline,vertical_tab,form_feed,carriage_return)
      ans = .true.
    case default
      ans = .false.
    end select
  end function ch_is_space
!===============================================================================

!===============================================================================
! ch_is_uppercase:
!
!   Returns .TRUE. if the given character is an upper case letter.
!
  pure function ch_is_uppercase( ch ) result( ans )
    character(kind=CK,len=1), intent(in) :: ch
    logical :: ans

    select case (ch)
    case ('A':'Z')
      ans = .true.
    case default
      ans = .false.
    end select
  end function ch_is_uppercase
!===============================================================================

!===============================================================================
! ch_convert_to_lowercase:
!
!   If given an upper case characer, converts it to it's lower case equivalent.
!
  pure subroutine ch_convert_to_lowercase( ch )
    character(kind=CK,len=1), intent(inout) :: ch
    ! local variables:
    integer :: ic

    ic = ichar(ch)
    if (64 < ic .and. ic < 91) ch = char(ic + 32)
  end subroutine ch_convert_to_lowercase
!===============================================================================

!===============================================================================
! ch_convert_to_uppercase:
!
!   If given a lower case characer, converts it to it's upper case equivalent.
!
  pure subroutine ch_convert_to_uppercase( ch )
    character(kind=CK,len=1), intent(inout) :: ch
    ! local variables:
    integer :: ic

    ic = ichar(ch)
    if (96 < ic .and. ic < 123) ch = char(ic - 32)
  end subroutine ch_convert_to_uppercase
!===============================================================================

!===============================================================================
! str_convert_to_lowercase:
!
!   Converts upper case characters in the given character string to lower case.
!
  pure subroutine str_convert_to_lowercase( str )
    character(kind=CK,len=*), intent(inout) :: str
    ! local variables:
    integer :: i, ic

    do i = 1, len_trim(str)
      call ch_convert_to_lowercase(str(i:i))
    end do
  end subroutine str_convert_to_lowercase
!===============================================================================

!===============================================================================
! str_convert_to_uppercase:
!
!   Takes character array and coverts all characters a-z to upper-case.
!   Conversion is done in place.
!
  pure subroutine str_convert_to_uppercase( str )
    character(kind=CK,len=*), intent(inout) :: str
    ! local variables:
    integer :: i, ic

    do i = 1, len_trim(str)
      call ch_convert_to_uppercase(str(i:i))
    end do
  end subroutine str_convert_to_uppercase
!===============================================================================

!===============================================================================
! str_get_next_character:
!
!   Gets the next non-whitespace character from the given string. If no such
!   characters are found then a space is returned.
!
  pure subroutine str_get_next_character( str, ch, ich )
    character(kind=CK,len=*), intent(in)  :: str
    character(kind=CK,len=1), intent(out) :: ch
    integer, intent(inout), optional :: ich
    ! local variables:
    integer :: i
    integer :: i0

    if (present(ich)) then
      i0 = ich
    else
      i0 = 1
    end if

    ch = ' '
    do i = i0, len_trim(str)
      select case (str(i:i))
      case (space,tab)
        continue
      case default
        ch = str(i:i)
        exit
      end select
    end do

    if (present(ich)) ich = i
  end subroutine str_get_next_character
!===============================================================================

!===============================================================================
! str_is_integer:
!
!   Returns .TRUE. if the given string contains an integer value. Returns
!   .FALSE. otherwise.
!
!       ans   |F |F      |T  |F    |F      |T    |T|
!       stage |0 |1      |2  |3    |4      |5    |6|
!       regex |   [\+\-]? \d* ([eE] [\+\-]? \d+)?  |
!
  function str_is_integer( str, allow_spaces ) result( ans )
    character(kind=CK,len=*), intent(in) :: str
    logical, intent(in), optional :: allow_spaces
    logical :: ans
    ! local variables:
    integer :: i
    logical :: no_spaces
    logical :: not_integer
    integer :: stage

    if (present(allow_spaces)) then
      no_spaces = .not.allow_spaces
    else
      no_spaces = .false.
    end if

    ! determine number type and length
    stage = 0
    not_integer = .false.
    do i = 1, len(str)
      select case(str(i:i))
      case (space,tab)
        ! white space
        select case (stage)
        case (0,6)
          not_integer = no_spaces
        case (2,5)
          not_integer = no_spaces
          stage = 6
        case default
          not_integer = .true.
        end select
      case ('-')
        ! minus sign
        select case(stage)
        case(0)
          stage = 1
        case default
          not_integer = .true.
        end select
      case ('+')
        ! plus sign
        select case(stage)
        case(0)
          stage = 1
        case(3)
          stage = 4
        case default
          not_integer = .true.
        end select
      case ('0':'9')
        ! digit
        select case(stage)
        case(0:1)
          stage = 2
        case(3:4)
          stage = 5
        case default
          continue
        end select
      case ('e','E')
        ! exponent
        select case(stage)
        case(2)
          stage = 3
        case default
          not_integer = .true.
        end select
      case default
        not_integer = .true.
      end select

      if (not_integer) exit
    end do

    ! determine if integer
    if (not_integer) then
      ans = .false.
    else
      select case (stage)
      case (2,5,6)
        ans = .true.
      case default
        ans = .false.
      end select
    end if
  end function str_is_integer
!===============================================================================

!===============================================================================
! str_is_real:
!
!   Returns .TRUE. if the given string contains a real value. Returns .FALSE.
!   otherwise.
!       ans   |F |F      |T  |T   |T  |F      |F      |T     |T|
!       stage |0 |1      |2  |3   |4  |5      |6      |7     |8|
!       regex |   [\+\-]? \d* (\.? \d* ([deDE] [\+\-]? \d+)?)  |
!
  pure function str_is_real( str, allow_spaces ) result( ans )
    character(kind=CK,len=*), intent(in) :: str
    logical, intent(in), optional :: allow_spaces
    logical :: ans
    ! local variables:
    integer :: i
    logical :: has_leading_digit
    logical :: no_spaces
    logical :: not_real
    integer :: stage

    if (present(allow_spaces)) then
      no_spaces = .not.allow_spaces
    else
      no_spaces = .false.
    end if

    ! determine number type and length
    stage = 0
    not_real = .false.
    has_leading_digit = .false.
    do i = 1, len(str)
      select case(str(i:i))
      case (SPACE,TAB)
        ! white space
        select case (stage)
        case (0,8)
          not_real = no_spaces
          continue
        case (2:4,7)
          not_real = no_spaces
          stage = 8
        case default
          not_real = .true.
        end select
      case ('+','-')
        select case(stage)
        case(0)
          stage = 1
        case(5)
          stage = 6
        case default
          not_real = .true.
        end select
      case ('0':'9')
        select case(stage)
        case(0:1)
          stage = 2
          has_leading_digit = .true.
        case(3)
          stage = 4
        case(5:6)
          stage = 7
        case default
          continue
        end select
      case ('.')
        select case(stage)
        case(0:2)
          stage = 3
        case default
          not_real = .true.
        end select
      case ('e','E','d','D')
        select case(stage)
        case(2:4)
          stage = 5
        case default
          not_real = .true.
        end select
      case default
        not_real = .true.
      end select

      if (not_real) exit
    end do

    ! determine if real
    if (not_real) then
      ans = .false.
    else
      select case (stage)
      case (2,4,7,8)
        ans = .true.
      case (3)
        ans = has_leading_digit
      case default
        ans = .false.
      end select
    end if
  end function str_is_real
!===============================================================================

!===============================================================================
! str_loc_end_delimeter:
!
!   Returns the location of the last delimiter from the start of the given
!   string (first non-delimiter character position -1). Returns 0 if no
!   delimiter characters are found.
!
  pure function str_loc_end_delimeter( str ) result( val )
    character(kind=CK,len=*), intent(in)  :: str
    integer :: val

    val = verify(str, DELIMITERS)
    if (val == 0) then
      val = len(str)
    else
      val = val - 1
    end if
  end function str_loc_end_delimeter
!===============================================================================

!===============================================================================
! str_loc_end_token:
!
!   Returns the location of the last valid token character starting from the
!   begining of the string. Returns 0 if no valid token characters were found.
!
  pure function str_loc_end_token( str ) result( val )
    character(kind=CK,len=*), intent(in)  :: str
    integer :: val

    ! find first delimiter character
    val = scan(str, DELIMITERS)
    if (val == 0) then
      ! no delimiter characters were found
      val = len(str)
    else
      val = val - 1
    end if
  end function str_loc_end_token
!===============================================================================

!===============================================================================
! str_loc_next_delimeter:
!
!   Returns the location of the first delimiter character in the given string.
!   Returns 0 if no delimiter is found.
!
  pure function str_loc_next_delimiter( str ) result( val )
    character(kind=CK,len=*), intent(in)  :: str
    integer :: val

    val = scan(str, DELIMITERS)
  end function str_loc_next_delimiter
!===============================================================================

!===============================================================================
! str_loc_next_letter:
!
!   Returns the location of the first letter in the given string. Returns 0 if
!   no letter is found.
!
  pure function str_loc_next_letter( str ) result( val )
    character(kind=CK,len=*), intent(in)  :: str
    integer :: val

    val = scan(str, LETTERS)
  end function str_loc_next_letter
!===============================================================================

!===============================================================================
! str_loc_next_real:
!
!   Returns .TRUE. if the given string contains a real value. Returns .FALSE.
!   otherwise.
!       ans   |F |F      |T  |T   |T  |F      |F      |T     |T|
!       stage |0 |1      |2  |3   |4  |5      |6      |7     |8|
!       regex |   [\+\-]? \d* (\.? \d* ([deDE] [\+\-]? \d+)?)  |
!
  pure function str_loc_next_real( str ) result( loc )
    character(kind=CK,len=*), intent(in) :: str
    integer :: loc
    ! local variables:
    integer :: i, i0
    logical :: has_leading_digit
    integer :: stage


    ! determine number type and length
    stage = 0
    has_leading_digit = .false.
    do i = 1, len(str)
      if (stage == 0) i0 = i

      select case(str(i:i))
      case (SPACE,TAB,NEWLINE,CARRIAGE_RETURN,';',':',',','{','}','(',')','[',']')
        select case(stage)
        case(-1)
          stage = 0
        case (2:4,7)
          stage = 8
        end select
      case ('+','-')
        select case(stage)
        case(0)
          stage = 1
        case(5)
          stage = 6
        case default
          stage = -1
        end select
      case ('0':'9')
        select case(stage)
        case(0:1)
          stage = 2
          has_leading_digit = .true.
        case(3)
          stage = 4
        case(5:6)
          stage = 7
        case default
          continue
        end select
      case ('.')
        select case(stage)
        case(0:2)
          stage = 3
        case default
          stage = -1
        end select
      case ('e','E','d','D')
        select case(stage)
        case(2,4)
          stage = 5
        case (3)
          if (has_leading_digit) then
            stage = 5
          else
            stage = -1
          end if
        case default
          stage = -1
        end select
      case default
        stage = -1
      end select

      if (stage == 8) exit
      if (stage == -1) has_leading_digit = .false.
    end do

    loc = 0
    select case(stage)
    case (2,4,7,8)
      loc = i0
    case (3)
      if (has_leading_digit) loc = i0
    end select
  end function str_loc_next_real
!===============================================================================

!===============================================================================
! str_loc_next_space:
!
!   Returns the location of the first space in the given string. Returns 0 if no
!   space is found.
!
  pure function str_loc_next_space( str ) result( val )
    character(kind=CK,len=*), intent(in)  :: str
    integer :: val

    val = scan(str, SPACES)
  end function str_loc_next_space
!===============================================================================

!===============================================================================
! str_loc_next_token:
!
!   Returns the location of the last delimiter from the start of the given
!   string (first non-delimiter character position -1). Returns 0 if no
!   delimiter characters are found.
!
  pure subroutine str_loc_next_token( str, i0, i1 )
    character(kind=CK,len=*), intent(in)  :: str
    integer, intent(inout) :: i0
    integer, intent(inout) :: i1

    i0 = str_loc_start_token(str)
    if (i0 == 0) then
      i1 = 0
    else
      i1 = i0 + str_loc_end_token(str(i0:)) - 1
    end if
  end subroutine str_loc_next_token
!===============================================================================

!===============================================================================
! str_loc_start_token:
!
!   Returns the location of the first valid token character. Returns 0 if no
!   valid token characters are found.
!
  pure function str_loc_start_token( str ) result( val )
    character(kind=CK,len=*), intent(in)  :: str
    integer :: val

    ! find the first non-delimiter character
    val = verify(str, DELIMITERS)
  end function str_loc_start_token
!===============================================================================

!===============================================================================
! str_lowercase:
!
!   Returns given string with all characters A-Z converted to lower case.
!
  pure function str_lowercase( str ) result( lstr )
    character(kind=CK,len=*), intent(in) :: str
    character(:), allocatable :: lstr
    lstr = str
    call str_convert_to_lowercase(lstr)
  end function str_lowercase
!===============================================================================

!===============================================================================
! str_parse_next_token:
!
!   Returns the location of the last delimiter from the start of the given
!   string (first non-delimiter character position -1). Returns 0 if no
!   delimiter characters are found.
!
  pure subroutine str_parse_next_token( str, i, token )
    character(kind=CK,len=*), intent(in)  :: str
    integer, intent(inout) :: i
    character(kind=CK,len=:), allocatable, intent(out) :: token
    ! local characters:
    integer :: i0, i1

    call str_loc_next_token(str(i:), i0, i1)
    if (i0 == 0) then
      token = ''
      i = len_trim(str)
    else
      i0 = i0 + i - 1
      i1 = i1 + i - 1
      token = str(i0:i1)
      i = i1 + 1
    end if
  end subroutine str_parse_next_token
!===============================================================================

!===============================================================================
! str_uppercase:
!
!   Returns given string with all characters a-z converted to upper case.
!
  pure function str_uppercase( str ) result( ustr )
    character(kind=CK,len=*), intent(in) :: str
    character(:), allocatable :: ustr
    ustr = str
    call str_convert_to_uppercase(ustr)
  end function str_uppercase
!===============================================================================
end module string_utility_module
!===============================================================================
